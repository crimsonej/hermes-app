const test = require('node:test');
const assert = require('node:assert/strict');
const { createMt5BridgeServer } = require('../scripts/mt5-bridge.js');

function startServer() {
  return new Promise((resolve) => {
    const server = createMt5BridgeServer(0);
    server.listen(0, () => {
      const { port } = server.address();
      resolve({ server, port });
    });
  });
}

test('mt5 bridge health endpoint works', async () => {
  const { server, port } = await startServer();

  try {
    const res = await fetch(`http://127.0.0.1:${port}/health`);
    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.ok, true);
    assert.equal(body.service, 'mt5-bridge');
  } finally {
    server.close();
  }
});

test('mt5 bridge accepts a valid order payload', async () => {
  const { server, port } = await startServer();

  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/order`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        symbol: 'EURUSD',
        action: 'buy',
        volume: 0.01,
        price: 1.1,
        stopLoss: 1.095,
        takeProfit: 1.11,
        comment: 'hermes',
        source: 'hermes'
      })
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.ok, true);
    assert.equal(body.symbol, 'EURUSD');
    assert.equal(body.action, 'buy');
    assert.ok(body.orderId);
  } finally {
    server.close();
  }
});

test('mt5 bridge rejects invalid order payloads', async () => {
  const { server, port } = await startServer();

  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/order`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'buy', volume: 0 })
    });

    const body = await res.json();
    assert.equal(res.status, 400);
    assert.equal(body.ok, false);
    assert.match(body.error, /symbol|volume/i);
  } finally {
    server.close();
  }
});
