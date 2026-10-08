const http = require('http');
const fs = require('fs');
const path = require('path');

function normalizeOrder(payload = {}) {
  const symbol = String(payload.symbol || payload.instrument || payload.pair || '').trim();
  const action = String(payload.action || payload.type || payload.side || '').trim().toLowerCase();
  const volume = Number(payload.volume || payload.lot || payload.qty || 0.01);
  const price = Number(payload.price || payload.entry || 0);
  const stopLoss = Number(payload.stopLoss || payload.sl || 0);
  const takeProfit = Number(payload.takeProfit || payload.tp || 0);
  const comment = String(payload.comment || 'hermes').trim();

  if (!symbol) {
    throw new Error('symbol is required');
  }
  if (!['buy', 'sell', 'buy_stop', 'sell_stop', 'buy_limit', 'sell_limit'].includes(action)) {
    throw new Error('action must be one of buy, sell, buy_limit, sell_limit, buy_stop, sell_stop');
  }
  if (!Number.isFinite(volume) || volume <= 0) {
    throw new Error('volume must be a positive number');
  }

  return {
    symbol,
    action,
    volume,
    price,
    stopLoss,
    takeProfit,
    comment,
    source: String(payload.source || 'hermes')
  };
}

function persistOrder(record) {
  const dataDir = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
  fs.mkdirSync(dataDir, { recursive: true });
  const ordersPath = path.join(dataDir, 'mt5-orders.json');

  let orders = [];
  if (fs.existsSync(ordersPath)) {
    try {
      const raw = fs.readFileSync(ordersPath, 'utf8');
      const parsed = JSON.parse(raw);
      orders = Array.isArray(parsed) ? parsed : [];
    } catch (err) {
      orders = [];
    }
  }

  orders.push(record);
  fs.writeFileSync(ordersPath, JSON.stringify(orders, null, 2), 'utf8');
  return ordersPath;
}

function createMt5BridgeServer(port = Number(process.env.MT5_BRIDGE_PORT) || 4100) {
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);

    if (req.method === 'GET' && url.pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: true, service: 'mt5-bridge', status: 'healthy', timestamp: new Date().toISOString() }));
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/order') {
      let body = '';
      req.on('data', chunk => {
        body += chunk;
      });

      req.on('end', () => {
        try {
          const payload = body ? JSON.parse(body) : {};
          const order = normalizeOrder(payload);
          const record = {
            ...order,
            orderId: `mt5-${Date.now()}`,
            status: 'accepted',
            serverTime: new Date().toISOString(),
            backend: 'mt5-bridge'
          };

          persistOrder(record);

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, ...record }));
        } catch (err) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: false, error: err.message || 'Invalid MT5 order payload.' }));
        }
      });
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: false, error: 'Not found' }));
  });

  return server;
}

if (require.main === module) {
  const port = Number(process.env.MT5_BRIDGE_PORT) || 4100;
  const server = createMt5BridgeServer(port);
  server.listen(port, () => {
    console.log(`[mt5-bridge] listening on http://0.0.0.0:${port}`);
  });
}

module.exports = { createMt5BridgeServer, normalizeOrder, persistOrder };
