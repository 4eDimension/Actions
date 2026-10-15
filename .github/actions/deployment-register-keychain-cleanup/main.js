'use strict';

const fs = require('fs');

const keychainPath = (process.env.INPUT_KEYCHAIN_PATH || '').trim();
const stateFile = process.env.GITHUB_STATE;

if (!keychainPath) {
  console.log('⚠️ No KEYCHAIN_PATH provided — post cleanup will use RUNNER_TEMP default');
}

if (stateFile) {
  fs.appendFileSync(stateFile, `KEYCHAIN_PATH=${keychainPath}\n`);
}

console.log(`🔒 Registered keychain cleanup for: ${keychainPath || '(default)'}`);
