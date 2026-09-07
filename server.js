const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const TRADING_MODE = process.env.HERMES_TRADING_MODE || 'paper';

fs.mkdirSync(DATA_DIR, { recursive: true });

app.use(express.json({ limit: '10mb' }));

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    service: 'hermes-app',
    tradingMode: TRADING_MODE,
    dataDir: DATA_DIR,
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.json({
    name: 'Hermes App',
    status: 'running',
    tradingMode: TRADING_MODE,
    dataDir: DATA_DIR,
    endpoints: ['/health', '/api/write-data', '/api/read-data']
  });
});

app.post('/api/write-data', (req, res) => {
  const { fileName, content } = req.body || {};

  if (!fileName) {
    return res.status(400).json({ error: 'fileName is required' });
  }

  const safeName = fileName.replace(/\.{2,}/g, '').replace(/\\/g, '/');
  const targetPath = path.join(DATA_DIR, safeName);
  const targetDir = path.dirname(targetPath);

  fs.mkdirSync(targetDir, { recursive: true });

  const data = typeof content === 'string' ? content : JSON.stringify(content, null, 2);
  fs.writeFileSync(targetPath, data, 'utf8');

  return res.json({
    ok: true,
    file: safeName,
    path: targetPath
  });
});

app.get('/api/read-data', (req, res) => {
  const fileName = req.query.fileName || 'state.json';
  const safeName = String(fileName).replace(/\.{2,}/g, '').replace(/\\/g, '/');
  const targetPath = path.join(DATA_DIR, safeName);

  if (!fs.existsSync(targetPath)) {
    return res.status(404).json({ error: 'file not found' });
  }

  const content = fs.readFileSync(targetPath, 'utf8');
  res.type('application/json');
  return res.send(content);
});

app.listen(PORT, () => {
  console.log(`Hermes app listening on port ${PORT}`);
  console.log(`Data directory: ${DATA_DIR}`);
});
