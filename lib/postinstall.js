const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const dirs = ["mcp", "ui"];

for (const dir of dirs) {
  const pkg = path.resolve(__dirname, "..", dir, "package.json");
  if (fs.existsSync(pkg)) {
    try {
      execSync("npm install --silent", {
        cwd: path.resolve(__dirname, "..", dir),
        stdio: "ignore",
      });
    } catch {
      // non-fatal — mcp or ui deps may fail on some systems
    }
  }
}
