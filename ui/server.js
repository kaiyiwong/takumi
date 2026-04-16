const express = require('express');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;
const TAKUMI = path.resolve(__dirname, '..', 'takumi.sh');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Job store for polling-based output
let jobId = 0;
const jobs = {};

// Start a takumi command, returns a job ID
app.post('/api/run', (req, res) => {
  const { command, args } = req.body;

  const allowed = [
    'cc',
    'convert',
    'trim',
    'thumb',
    'info',
    'gif',
    'strip',
    'srt2vtt',
    'vtt2srt',
  ];

  if (!allowed.includes(command)) {
    return res.status(400).json({ error: 'Invalid command' });
  }

  const id = ++jobId;
  const job = { output: '', done: false, code: 0 };
  jobs[id] = job;

  const proc = spawn('bash', [TAKUMI, command, ...args], {
    env: { ...process.env },
  });

  proc.stdout.on('data', (chunk) => {
    job.output += chunk.toString();
  });
  proc.stderr.on('data', (chunk) => {
    job.output += chunk.toString();
  });

  proc.on('close', (code) => {
    job.done = true;
    job.code = code || 0;
    // Clean up after 60s
    setTimeout(() => delete jobs[id], 60000);
  });

  proc.on('error', (err) => {
    job.output += '\nError: ' + err.message;
    job.done = true;
    job.code = 1;
  });

  res.json({ id });
});

// Poll for job output
app.get('/api/poll/:id', (req, res) => {
  const job = jobs[parseInt(req.params.id, 10)];
  if (!job) return res.json({ output: '', done: true, code: 1 });

  const offset = parseInt(req.query.offset || '0', 10);
  const newOutput = job.output.slice(offset);

  res.json({
    output: newOutput,
    offset: job.output.length,
    done: job.done,
    code: job.code,
  });
});

// Native macOS file/folder picker
app.get('/api/pick', (req, res) => {
  // Single dialog: choose folder (users can also see and navigate to files within)
  // We use 'choose folder' since it lets users navigate the filesystem naturally
  // and most takumi commands work on folders anyway
  const mode = req.query.mode || 'file';
  const script =
    mode === 'folder'
      ? 'POSIX path of (choose folder with prompt "Select a folder")'
      : 'POSIX path of (choose file with prompt "Select a file")';

  const proc = spawn('osascript', ['-e', script]);
  let out = '';

  proc.stdout.on('data', (chunk) => {
    out += chunk.toString();
  });

  proc.on('close', () => {
    const cleaned = out.trim().replace(/\/$/, '');
    if (cleaned) {
      res.json({ path: cleaned });
    } else {
      res.json({ path: '', cancelled: true });
    }
  });
});

const fs = require('fs');

const START_PORT = 3000;
const PORT_FILE = path.join(__dirname, '.port');

function startServer(port) {
  const server = app.listen(port, () => {
    console.log(`🔧 takumi UI running at http://localhost:${port}`);
    fs.writeFileSync(PORT_FILE, String(port));
  });
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`   Port ${port} in use, trying ${port + 1}...`);
      startServer(port + 1);
    } else {
      throw err;
    }
  });
}

startServer(START_PORT);
