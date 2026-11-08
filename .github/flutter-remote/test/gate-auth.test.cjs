const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const http = require('node:http');
const path = require('node:path');
const { once } = require('node:events');
const { setTimeout: delay } = require('node:timers/promises');
const { test } = require('node:test');

const TOKEN = 'local-gate-regression-test';

function request(port, headers = {}, requestPath = '/') {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port, path: requestPath, headers, agent: false }, (response) => {
      let body = '';
      response.setEncoding('utf8');
      response.on('data', (chunk) => { body += chunk; });
      response.on('end', () => resolve({ status: response.statusCode, headers: response.headers, body }));
    }).on('error', reject);
  });
}

test('gate authenticates proxied HTTP and WebSocket requests to serve-sim', { timeout: 10000 }, async (t) => {
  let upstreamRequests = 0;
  const upstream = http.createServer((req, res) => {
    upstreamRequests++;
    res.writeHead(req.headers.authorization === `Bearer ${TOKEN}` ? 200 : 403, { 'Content-Type': 'text/plain' });
    res.end('simulator');
  });
  upstream.on('upgrade', (req, socket) => {
    if (req.headers.authorization !== `Bearer ${TOKEN}`) {
      socket.end('HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\n\r\n');
      return;
    }
    socket.write('HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n');
  });
  upstream.listen(0, '127.0.0.1');
  await once(upstream, 'listening');
  t.after(() => upstream.close());

  const reservation = http.createServer();
  reservation.listen(0, '127.0.0.1');
  await once(reservation, 'listening');
  const gatePort = reservation.address().port;
  await new Promise((resolve) => reservation.close(resolve));

  const gate = spawn(process.execPath, [path.join(__dirname, '../gate.cjs')], {
    env: {
      ...process.env,
      FLUTTER_REMOTE_GATE_TOKEN: TOKEN,
      FLUTTER_REMOTE_GATE_PORT: String(gatePort),
      FLUTTER_REMOTE_TARGET_PORT: String(upstream.address().port),
      FLUTTER_REMOTE_STREAM_RELAY: '0',
    },
    stdio: 'ignore',
    windowsHide: true,
  });
  t.after(async () => {
    if (gate.exitCode === null) {
      gate.kill();
      await once(gate, 'exit');
    }
  });
  let ready = false;
  for (let attempt = 0; attempt < 100; attempt++) {
    try {
      ready = (await request(gatePort, {}, '/__flutter-remote/healthz')).status === 200;
      if (ready) break;
    } catch {}
    await delay(25);
  }
  assert.equal(ready, true, 'gate should start');

  assert.equal((await request(gatePort)).status, 403, 'unauthenticated clients stay blocked');
  const login = await request(gatePort, {}, `/?k=${TOKEN}`);
  assert.equal(login.status, 302);
  const cookie = login.headers['set-cookie'][0].split(';')[0];
  const preview = await request(gatePort, { cookie, authorization: 'Bearer wrong-upstream-token' });
  assert.equal(preview.status, 200, 'gate supplies the configured upstream token');
  assert.equal(preview.body, 'simulator');

  assert.equal((await request(gatePort, {}, '/player')).status, 403);
  const playerLogin = await request(gatePort, {}, `/player?k=${TOKEN}`);
  assert.equal(playerLogin.status, 302);
  assert.equal(playerLogin.headers.location, '/player');
  const countBeforePlayer = upstreamRequests;
  const player = await request(gatePort, { cookie }, '/player');
  assert.equal(player.status, 200);
  assert.match(player.body, /id="flutter-remote-container"/);
  assert.match(player.body, /src="\/__flutter-remote\/client\.js"/);
  assert.equal(player.body.includes(TOKEN), false);
  assert.equal(upstreamRequests, countBeforePlayer, 'standalone player must not load serve-sim UI');

  await new Promise((resolve, reject) => {
    const req = http.request({
      host: '127.0.0.1', port: gatePort, path: '/helper/test/ws',
      headers: { cookie, connection: 'Upgrade', upgrade: 'websocket' },
    });
    req.on('upgrade', (response, socket) => {
      socket.destroy();
      assert.equal(response.statusCode, 101);
      resolve();
    });
    req.on('response', (response) => {
      response.resume();
      reject(new Error(`WebSocket rejected with ${response.statusCode}`));
    });
    req.on('error', reject);
    req.end();
  });
});
