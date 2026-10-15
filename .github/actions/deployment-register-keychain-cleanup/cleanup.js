'use strict';

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

function run(cmd, args) {
  try {
    execFileSync(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    return true;
  } catch {
    return false;
  }
}

function defaultKeychain() {
  try {
    const out = execFileSync('security', ['default-keychain', '-d', 'user'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return out
      .split('\n')
      .map((line) => line.replace(/^\s*"/, '').replace(/"\s*$/, '').trim())
      .find(Boolean) || '';
  } catch {
    return '';
  }
}

const runnerTemp = process.env.RUNNER_TEMP || '';
const kc =
  (process.env.STATE_KEYCHAIN_PATH || '').trim() ||
  (runnerTemp ? path.join(runnerTemp, 'temp.keychain-db') : '');

const home = os.homedir();
const loginCandidates = [
  path.join(home, 'Library/Keychains/login.keychain-db'),
  path.join(home, 'Library/Keychains/login.keychain'),
];
const login = loginCandidates.find((p) => fs.existsSync(p));
const currentDefault = defaultKeychain();

if (kc) {
  // delete-keychain also removes the entry from the user search list
  run('security', ['delete-keychain', kc]);
  try {
    fs.unlinkSync(kc);
  } catch {
    /* ignore */
  }
  try {
    fs.unlinkSync(`${kc}-db`);
  } catch {
    /* ignore */
  }
}

// Only restore default if *this* job owned it — never reset globally (parallel jobs)
if (kc && currentDefault === kc && login) {
  run('security', ['default-keychain', '-s', login]);
}

console.log(`✅ Temp keychain cleaned: ${kc || '(none)'}`);
