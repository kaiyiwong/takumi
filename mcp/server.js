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
    "Convert videos to optimized MP4. Profiles: 'web' (default, plays everywhere), 'firetv' (FireTV app assets, mod16 dimensions), 'small' (compressed for email/Slack/low bandwidth, 720p), 'hq' (high quality for portfolio/client delivery). Pick the profile that matches the user's intent.",
    {
      path: z.string().describe("Path to video file or folder"),
      profile: z.enum(["web", "firetv", "small", "hq"]).optional().describe("Conversion profile: 'web' for websites/general use, 'firetv' for FireTV apps, 'small' for email/Slack/sharing, 'hq' for portfolio/client delivery. Default: web"),
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
    "takumi_trim",
    "Cut a clip between two timestamps",
    {
      path: z.string().describe("Path to video file"),
      start: z.string().describe("Start timestamp (HH:MM:SS or HH:MM:SS.mmm)"),
      end: z.string().describe("End timestamp (HH:MM:SS or HH:MM:SS.mmm)"),
    },
    async ({ path: p, start, end }) => {
      return run(["trim", p, start, end]);
    }
  );

  server.tool(
    "takumi_thumb",
    "Extract a poster image (JPG) from a video",
    {
      path: z.string().describe("Path to video file or folder"),
      timestamp: z.string().optional().describe("Timestamp to capture (default 00:00:01)"),
    },
    async ({ path: p, timestamp }) => {
      const args = ["thumb", p];
      if (timestamp) args.push(timestamp);
      return run(args);
    }
  );

  server.tool(
    "takumi_info",
    "Show video metadata (resolution, codec, duration, etc.)",
    {
      path: z.string().describe("Path to video file or folder"),
    },
    async ({ path: p }) => {
      return run(["info", p]);
    }
  );

  server.tool(
    "takumi_gif",
    "Create an animated GIF from a video clip",
    {
      path: z.string().describe("Path to video file"),
      start: z.string().describe("Start timestamp"),
      end: z.string().describe("End timestamp"),
      width: z.number().optional().describe("GIF width in pixels (default 480)"),
    },
    async ({ path: p, start, end, width }) => {
      const args = ["gif", p, start, end];
      if (width !== undefined) args.push(String(width));
      return run(args);
    }
  );

  server.tool(
    "takumi_strip",
    "Extract audio and/or video as separate tracks",
    {
      path: z.string().describe("Path to video file or folder"),
      mode: z.enum(["audio", "video", "both"]).describe("What to extract: audio, video, or both"),
    },
    async ({ path: p, mode }) => {
      return run(["strip", p, mode]);
    }
  );

  server.tool(
    "takumi_srt2vtt",
    "Convert SRT subtitle files to VTT format",
    {
      path: z.string().describe("Path to SRT file or folder"),
    },
    async ({ path: p }) => {
      return run(["srt2vtt", p]);
    }
  );

  server.tool(
    "takumi_vtt2srt",
    "Convert VTT subtitle files to SRT format",
    {
      path: z.string().describe("Path to VTT file or folder"),
    },
    async ({ path: p }) => {
      return run(["vtt2srt", p]);
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error("Failed to start takumi MCP server:", err);
  process.exit(1);
});
