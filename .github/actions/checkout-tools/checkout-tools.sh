#!/usr/bin/env bash
# Hardened clone of 4eDimension/Tools for CI runners.
# - HTTP/1.1 (avoid curl 92 HTTP/2 resets)
# - Abort stalled transfers (lowSpeed*) + hard timeout per attempt
# - No interactive credential helper (prevents infinite hangs)
# - Retries with final non-partial-clone fallback
set -euo pipefail

: "${TOKEN:?TOKEN required}"
: "${REF:?REF required}"
: "${DEST:?DEST required}"
: "${SPARSE:?SPARSE required}"
: "${REPO:?REPO required}"

CLONE_TIMEOUT_SEC="${CLONE_TIMEOUT_SEC:-600}"   # 10 min per clone attempt
SPARSE_TIMEOUT_SEC="${SPARSE_TIMEOUT_SEC:-600}" # 10 min for sparse materialize

run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout --signal=KILL "${seconds}" "$@"
    return $?
  fi
  # macOS / environments without GNU timeout
  "$@" &
  local pid=$!
  (
    sleep "${seconds}"
    if kill -0 "${pid}" 2>/dev/null; then
      echo "⏰ Timeout ${seconds}s — kill PID ${pid}: $*"
      kill -TERM "${pid}" 2>/dev/null || true
      sleep 5
      kill -KILL "${pid}" 2>/dev/null || true
    fi
  ) &
  local watcher=$!
  set +e
  wait "${pid}"
  local st=$?
  set -e
  kill "${watcher}" 2>/dev/null || true
  wait "${watcher}" 2>/dev/null || true
  # 143/137 = terminated by signal
  return "${st}"
}

# Prefer embedded URL token; never block on GUI/keychain credential helpers.
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=echo
export GCM_INTERACTIVE=never

git config --global http.version HTTP/1.1
git config --global http.postBuffer 524288000
# Abort if transfer stalls below ~1 KiB/s for 60s (was 0 = hang forever)
git config --global http.lowSpeedLimit 1024
git config --global http.lowSpeedTime 60
git config --global core.compression 0
git config --global credential.helper ""

DEST_ABS="${GITHUB_WORKSPACE}/${DEST}"
URL="https://x-access-token:${TOKEN}@github.com/${REPO}.git"

SPARSE_ARGS=()
while IFS= read -r line || [ -n "$line" ]; do
  line="$(printf '%s' "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -n "$line" ] || continue
  SPARSE_ARGS+=("$line")
done <<< "$SPARSE"

if [ "${#SPARSE_ARGS[@]}" -eq 0 ]; then
  echo "❌ sparse-paths vide"
  exit 1
fi

attempt=1
max_attempts=5
delay=15

while [ "$attempt" -le "$max_attempts" ]; do
  echo "📦 Checkout ${REPO}@${REF} → ${DEST} (attempt ${attempt}/${max_attempts}, timeout ${CLONE_TIMEOUT_SEC}s)"
  rm -rf "${DEST_ABS}"

  clone_ok=0
  set +e
  if [ "$attempt" -lt "$max_attempts" ]; then
    run_with_timeout "${CLONE_TIMEOUT_SEC}" \
      git -c credential.helper= -c http.version=HTTP/1.1 \
        clone --depth 1 --single-branch --branch "${REF}" --sparse \
        --filter=blob:none \
        "${URL}" "${DEST_ABS}"
    st=$?
  else
    echo "⚠️ Dernier essai SANS --filter=blob:none (plus fiable, plus lourd)"
    run_with_timeout "${CLONE_TIMEOUT_SEC}" \
      git -c credential.helper= -c http.version=HTTP/1.1 \
        clone --depth 1 --single-branch --branch "${REF}" --sparse \
        "${URL}" "${DEST_ABS}"
    st=$?
  fi
  set -e

  if [ "$st" -eq 0 ]; then
    clone_ok=1
  else
    echo "⚠️ git clone exit=${st}"
  fi

  if [ "$clone_ok" -eq 1 ]; then
    set +e
    run_with_timeout "${SPARSE_TIMEOUT_SEC}" \
      git -C "${DEST_ABS}" -c credential.helper= sparse-checkout set --cone "${SPARSE_ARGS[@]}"
    st=$?
    if [ "$st" -eq 0 ]; then
      run_with_timeout "${SPARSE_TIMEOUT_SEC}" \
        git -C "${DEST_ABS}" -c credential.helper= checkout -f HEAD
      st=$?
    fi
    set -e
    if [ "$st" -eq 0 ]; then
      echo "✅ Tools checkout OK (${DEST})"
      exit 0
    fi
    echo "⚠️ sparse-checkout / checkout a échoué (exit=${st})"
  fi

  rm -rf "${DEST_ABS}"
  if [ "$attempt" -eq "$max_attempts" ]; then
    break
  fi
  echo "⏳ Retry dans ${delay}s..."
  sleep "$delay"
  attempt=$((attempt + 1))
  delay=$((delay * 2))
  if [ "$delay" -gt 60 ]; then delay=60; fi
done

echo "❌ Impossible de cloner ${REPO}@${REF} après ${max_attempts} tentatives"
exit 1
