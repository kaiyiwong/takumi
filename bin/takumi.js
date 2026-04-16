#!/usr/bin/env node

const { spawn } = require("child_process");
const path = require("path");
const { findBash } = require("../lib/find-bash");

const bash = findBash();
if (!bash) {
  console.error(
    "Error: bash not found.\n" +
    "On Windows, install Git for Windows: https://git-scm.com/download/win\n" +
    "This provides bash which takumi needs to run."
  );
  process.exit(1);
}

const takumi = path.resolve(__dirname, "..", "takumi.sh");
const child = spawn(bash, [takumi, ...process.argv.slice(2)], {
  stdio: "inherit",
  env: { ...process.env, SCRIPT_DIR: path.resolve(__dirname, "..") },
});

child.on("close", (code) => process.exit(code ?? 0));
