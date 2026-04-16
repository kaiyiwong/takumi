const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const WIN_BASH_PATHS = [
  "C:\\Program Files\\Git\\bin\\bash.exe",
  "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
];

function findBash() {
  // macOS / Linux — bash is always available
  if (process.platform !== "win32") {
    return "bash";
  }

  // Windows — check Git for Windows first
  for (const p of WIN_BASH_PATHS) {
    if (fs.existsSync(p)) {
      return p;
    }
  }

  // Try PATH (maybe user has bash via scoop, msys2, etc.)
  try {
    execFileSync("bash", ["--version"], { stdio: "ignore" });
    return "bash";
  } catch {
    // ignore
  }

  return null;
}

module.exports = { findBash };
