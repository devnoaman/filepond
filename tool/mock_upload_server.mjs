#!/usr/bin/env node
// Mock upload endpoint for the Filepond Upload Lab (apps/example) and manual
// testing. No dependencies: `node tool/mock_upload_server.mjs [--port 3010]
// [--scenario success] [--throttle 64]`.
//
// The scenario comes from (first match): the `x-scenario` request header,
// the `?scenario=` query parameter, or --scenario.
//
//   success     200  text/plain pond id
//   created     201  {"filepond": "<id>"}        (exercises pondLocation)
//   serverError 500  {"message": "Disk full"}
//   validation  422  {"error": "File too large"}
//   network     socket destroyed mid-request
//   slow        200 after 3 s
//   flaky       first attempt per file name → 503, retries → 200
//   mixed       odd requests → 200, even → 500
//   random      70 % → 200, 30 % → 500
//
// --throttle N reads the request body at ~N KB/s so the app shows a real,
// gradual progress bar for large files (0 = unthrottled).

import http from 'node:http';
import { URL } from 'node:url';

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, arg, i, all) => {
    if (arg.startsWith('--')) acc.push([arg.slice(2), all[i + 1]]);
    return acc;
  }, []),
);
const port = Number(args.port ?? process.env.PORT ?? 3010);
const defaultScenario = args.scenario ?? 'success';
const throttleKbps = Number(args.throttle ?? 0);

const attempts = new Map();
let requestCount = 0;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function fileNameOf(req, head) {
  const match = /filename="([^"]+)"/.exec(head);
  return match ? match[1] : `file-${requestCount}`;
}

async function readBody(req) {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of req) {
    chunks.push(chunk);
    bytes += chunk.length;
    // Awaiting here applies backpressure: the client sends more slowly.
    if (throttleKbps > 0) await sleep((chunk.length / (throttleKbps * 1024)) * 1000);
  }
  return { bytes, head: Buffer.concat(chunks).subarray(0, 4096).toString('latin1') };
}

function send(res, status, body) {
  const isJson = typeof body !== 'string';
  res.writeHead(status, {
    'content-type': isJson ? 'application/json' : 'text/plain',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': '*',
  });
  res.end(isJson ? JSON.stringify(body) : body);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, '');
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (req.method !== 'POST') {
    return send(res, 200, {
      ok: true,
      hint: 'POST multipart/form-data here',
      scenarios: ['success', 'created', 'serverError', 'validation', 'network', 'slow', 'flaky', 'mixed', 'random'],
    });
  }

  const n = ++requestCount;
  const scenario = req.headers['x-scenario'] ?? url.searchParams.get('scenario') ?? defaultScenario;
  const started = Date.now();
  const { bytes, head } = await readBody(req);
  const name = fileNameOf(req, head);
  const attempt = (attempts.get(name) ?? 0) + 1;
  attempts.set(name, attempt);
  const id = `pond_${n}_${bytes}b`;

  const log = (status) =>
    console.log(
      `#${n} ${scenario.padEnd(11)} ${String(status).padEnd(4)} ${name} (${bytes} B, attempt ${attempt}, ${Date.now() - started} ms)`,
    );

  switch (scenario) {
    case 'created':
      log(201);
      return send(res, 201, { filepond: id });
    case 'serverError':
      log(500);
      return send(res, 500, { message: 'Disk full' });
    case 'validation':
      log(422);
      return send(res, 422, { error: 'File too large' });
    case 'network':
      log('DROP');
      return req.socket.destroy();
    case 'slow':
      await sleep(3000);
      log(200);
      return send(res, 200, id);
    case 'flaky':
      if (attempt === 1) {
        log(503);
        return send(res, 503, { message: 'Service unavailable, try again' });
      }
      log(200);
      return send(res, 200, id);
    case 'mixed':
      if (n % 2 === 0) {
        log(500);
        return send(res, 500, { message: 'Disk full' });
      }
      log(200);
      return send(res, 200, id);
    case 'random':
      if (Math.random() < 0.3) {
        log(500);
        return send(res, 500, { message: 'Random failure' });
      }
      log(200);
      return send(res, 200, id);
    default:
      log(200);
      return send(res, 200, id);
  }
});

server.listen(port, () => {
  console.log(`Filepond mock upload server on http://localhost:${port}/upload`);
  console.log(`default scenario: ${defaultScenario}${throttleKbps ? `, throttle ${throttleKbps} KB/s` : ''}`);
});
