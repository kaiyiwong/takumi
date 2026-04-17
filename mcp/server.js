#!/usr/bin/env node

const { McpServer } = require("@modelcontextprotocol/sdk/server/mcp.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { z } = require("zod");
const { execFile } = require("child_process");
const path = require("path");
const { findBash } = require("../lib/find-bash");

const BASH = findBash();
const TAKUMI = path.resolve(__dirname, "..", "takumi.sh");
const ENV = { ...process.env, SCRIPT_DIR: path.resolve(__dirname, "..") };

function result(text, isError = false) {
  return {
    content: [{ type: "text", text }],
    isError,
  };
}

function run(args) {
  if (!BASH) {
    return Promise.resolve(
      result("Error: bash not found. On Windows, install Git for Windows: https://git-scm.com/download/win", true)
    );
  }

  // Validate that file path args exist before running
  const filePath = args[1];
  if (filePath) {
    const fs = require("fs");
    if (!fs.existsSync(filePath)) {
      return Promise.resolve(result(`Error: file or folder not found: ${filePath}`, true));
    }
  }

  return new Promise((resolve) => {
    execFile(BASH, [TAKUMI, ...args], { timeout: 300_000, env: ENV }, (err, stdout, stderr) => {
      const output = [stdout, stderr].filter(Boolean).join("\n").trim();
      if (err && !output) {
        resolve(result(`Error (exit code ${err.code}): ${err.message}`, true));
      } else if (err) {
        resolve(result(`Error (exit code ${err.code}):\n${output}`, true));
      } else {
        resolve(result(output || "Done."));
      }
    });
  });
}

async function main() {
  const server = new McpServer({
    name: "takumi",
    version: "1.0.0",
  });

  server.tool(
    "takumi_cc",
    "Generate closed captions (SRT/VTT) from video using Whisper",
    {
      path: z.string().describe("Path to video file or folder"),
      language: z.string().optional().describe("Language code (e.g. ja, en)"),
      model: z.string().optional().describe("Whisper model (tiny, base, small, medium, large)"),
      format: z.string().optional().describe("Output format (srt or vtt)"),
    },
    async ({ path: p, language, model, format }) => {
      const args = ["cc", p];
      if (language) args.push(language);
      if (model) args.push(model);
      if (format) args.push(format);
      return run(args);
    }
  );

  server.tool(
    "takumi_convert",
    "Convert videos to optimized MP4. Choose a profile based on the user's intent:\n- 'web' (default): website, CMS, landing page, blog, general use, online publishing, embedding in a webpage\n- 'firetv': FireTV app, Amazon Fire tablet, streaming device, TV app assets, broadcast, set-top box\n- 'small': email attachment, Slack, Teams, Discord, SMS, quick preview, social sharing, file size matters, low bandwidth, mobile messaging\n- 'hq': portfolio, client deliverable, showreel, demo reel, presentation, archival, best possible quality",
    {
      path: z.string().describe("Path to video file or folder"),
      profile: z.enum(["web", "firetv", "small", "hq"]).optional().describe("Conversion profile. 'web': website/CMS/general use/embedding. 'firetv': FireTV/streaming device/TV app. 'small': email/Slack/Teams/Discord/messaging/quick share/preview/low bandwidth. 'hq': portfolio/client delivery/showreel/presentation/archival. Default: web"),
      crf: z.number().optional().describe("Quality override (18-28, lower = better)"),
      max_height: z.number().optional().describe("Max height override in pixels"),
    },
    async ({ path: p, profile, crf, max_height }) => {
      const args = ["convert", p];
      if (profile) args.push("--profile", profile);
      if (crf !== undefined) args.push("--crf", String(crf));
      if (max_height !== undefined) args.push("--max", String(max_height));
      return run(args);
    }
  );

  server.tool(
    "takumi_thumb",
    "Extract a poster image (JPG) from a video. Choose a profile based on the user's intent:\n- 'default' (default): original aspect ratio, no crop, general poster frame\n- 'youtube': YouTube thumbnail, 1280x720, video cover image, YouTube upload\n- 'og': Open Graph, social share, Twitter card, Facebook preview, link preview, 1200x630\n- 'square': Instagram, App Store, album art, avatar, profile image, 1080x1080",
    {
      path: z.string().describe("Path to video file or folder"),
      timestamp: z.string().optional().describe("Timestamp to capture (default 00:00:01)"),
      profile: z.enum(["default", "youtube", "og", "square"]).optional().describe("Thumbnail profile. 'default': original aspect ratio. 'youtube': 1280x720 YouTube spec. 'og': 1200x630 social share. 'square': 1080x1080 Instagram/App Store. Default: default"),
    },
    async ({ path: p, timestamp, profile }) => {
      const args = ["thumb", p];
      if (timestamp) args.push(timestamp);
      if (profile) args.push("--profile", profile);
      return run(args);
    }
  );

  server.tool(
    "takumi_gif",
    "Create an animated GIF from a video clip. Choose a profile based on the user's intent:\n- 'default' (default): general purpose, quick preview, simple animation\n- 'slack': Slack, Teams, Discord, chat apps, messaging, small file, low bandwidth\n- 'readme': GitHub README, documentation, project page, wiki, tutorial\n- 'hq': portfolio, Dribbble, presentation, showreel, demo, client deliverable, smooth animation",
    {
      path: z.string().describe("Path to video file"),
      start: z.string().describe("Start timestamp"),
      end: z.string().describe("End timestamp"),
      profile: z.enum(["default", "slack", "readme", "hq"]).optional().describe("GIF profile. 'default': general purpose 480px 15fps. 'slack': chat apps 360px 10fps small file. 'readme': GitHub/docs 720px 15fps. 'hq': portfolio/Dribbble 800px 24fps smooth. Default: default"),
      width: z.number().optional().describe("Width override in pixels"),
    },
    async ({ path: p, start, end, profile, width }) => {
      const args = ["gif", p, start, end];
      if (profile) args.push("--profile", profile);
      if (width !== undefined) args.push("--width", String(width));
      return run(args);
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error("Failed to start takumi MCP server:", err);
  process.exit(1);
});
