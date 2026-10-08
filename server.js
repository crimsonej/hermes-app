const express = require('express');
const fs = require('fs');
const path = require('path');
const { exec, execFile } = require('child_process');

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const TRADING_MODE = process.env.HERMES_TRADING_MODE || 'paper';
const MT5_MODE = process.env.MT5_MODE || 'bridge';
const MT5_CLI_BIN = process.env.MT5_CLI_BIN || '';
const MT5_BRIDGE_URL = process.env.MT5_BRIDGE_URL || '';
const MT5_EXECUTION_ENABLED = String(process.env.MT5_EXECUTION_ENABLED || 'false').toLowerCase() === 'true';

function mt5BackendStatus() {
  if (!MT5_EXECUTION_ENABLED) {
    return { ready: false, reason: 'MT5 execution is disabled.' };
  }

  if (MT5_BRIDGE_URL) {
    try {
      const url = new URL(MT5_BRIDGE_URL);
      return { ready: ['http:', 'https:'].includes(url.protocol), backend: 'bridge', reason: 'Bridge URL is configured.' };
    } catch (err) {
      return { ready: false, backend: 'bridge', reason: `Invalid MT5 bridge URL: ${err.message}` };
    }
  }

  if (MT5_CLI_BIN) {
    try {
      const stat = fs.existsSync(MT5_CLI_BIN) && fs.statSync(MT5_CLI_BIN).isFile();
      return { ready: stat, backend: 'cli', reason: stat ? 'CLI binary exists and is configured.' : `MT5 CLI path not found: ${MT5_CLI_BIN}` };
    } catch (err) {
      return { ready: false, backend: 'cli', reason: `MT5 CLI check failed: ${err.message}` };
    }
  }

  return { ready: false, reason: 'No MT5 backend configured. Set MT5_BRIDGE_URL or MT5_CLI_BIN.' };
}

const SIGNALS_DIR = path.join(DATA_DIR, 'signals');
const ANALYSES_DIR = path.join(DATA_DIR, 'analyses');

fs.mkdirSync(DATA_DIR, { recursive: true });
fs.mkdirSync(SIGNALS_DIR, { recursive: true });
fs.mkdirSync(ANALYSES_DIR, { recursive: true });

app.use(express.json({ limit: '10mb' }));

let lastBackupStatus = {
  timestamp: null,
  success: null,
  message: 'No backup run since server start.'
};

function normalizeTradePayload(trade = {}) {
  const symbol = trade.symbol || trade.instrument || trade.pair || '';
  const action = String(trade.action || trade.type || trade.side || '').toLowerCase();
  const volume = Number(trade.volume || trade.lot || trade.qty || 0.01);
  const price = Number(trade.price || trade.entry || 0);
  const stopLoss = Number(trade.stopLoss || trade.sl || 0);
  const takeProfit = Number(trade.takeProfit || trade.tp || 0);
  const comment = trade.comment || 'hermes';

  return {
    symbol,
    action,
    volume,
    price,
    stopLoss,
    takeProfit,
    comment,
    raw: trade
  };
}

function runMt5Trade(trade, callback) {
  if (!MT5_EXECUTION_ENABLED) {
    return callback(new Error('MT5 execution is disabled. Set MT5_EXECUTION_ENABLED=true.'));
  }

  const payload = normalizeTradePayload(trade);

  if (MT5_BRIDGE_URL) {
    fetch(MT5_BRIDGE_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
      .then(async res => {
        const data = await res.json().catch(() => ({}));
        if (!res.ok) {
          throw new Error(data.error || `Bridge request failed with ${res.status}`);
        }
        callback(null, { mode: 'bridge', ok: true, ...data, payload });
      })
      .catch(err => callback(err));
    return;
  }

  if (MT5_CLI_BIN) {
    const args = [
      '--symbol', payload.symbol,
      '--action', payload.action,
      '--volume', String(payload.volume),
      '--comment', payload.comment
    ];

    if (payload.price > 0) args.push('--price', String(payload.price));
    if (payload.stopLoss > 0) args.push('--sl', String(payload.stopLoss));
    if (payload.takeProfit > 0) args.push('--tp', String(payload.takeProfit));

    execFile(MT5_CLI_BIN, args, { cwd: __dirname }, (error, stdout, stderr) => {
      if (error) {
        return callback(error);
      }
      callback(null, {
        mode: 'cli',
        ok: true,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
        payload
      });
    });
    return;
  }

  callback(new Error('No MT5 execution backend is configured. Set MT5_BRIDGE_URL or MT5_CLI_BIN.'));
}

function triggerBackupScript(callback) {
  console.log('[Backup] Initiating backup process...');
  exec('bash scripts/backup.sh', { cwd: __dirname }, (error, stdout, stderr) => {
    const timestamp = new Date().toISOString();
    if (error) {
      const msg = stderr || error.message;
      console.error('[Backup Error]:', msg);
      lastBackupStatus = { timestamp, success: false, message: msg };
      if (callback) callback(false, msg);
    } else {
      const msg = stdout.trim() || 'Backup complete';
      console.log('[Backup Success]:', msg);
      lastBackupStatus = { timestamp, success: true, message: msg };
      if (callback) callback(true, msg);
    }
  });
}

// Scheduled automatic backups (default every 24h, set AUTO_BACKUP_HOURS=0 to disable)
const AUTO_BACKUP_HOURS = Number(process.env.AUTO_BACKUP_HOURS) || 24;
if (AUTO_BACKUP_HOURS > 0) {
  const ms = AUTO_BACKUP_HOURS * 60 * 60 * 1000;
  setInterval(() => {
    triggerBackupScript();
  }, ms);
  console.log(`[Backup System] Automatic backup scheduled every ${AUTO_BACKUP_HOURS} hours.`);
}

app.get('/health', (req, res) => {
  const mt5Status = mt5BackendStatus();
  res.json({
    ok: true,
    service: 'hermes-app',
    tradingMode: TRADING_MODE,
    mt5Mode: MT5_MODE,
    mt5ExecutionEnabled: MT5_EXECUTION_ENABLED,
    mt5Ready: mt5Status.ready,
    mt5Backend: mt5Status.backend || null,
    mt5Status: mt5Status.reason || 'OK',
    dataDir: DATA_DIR,
    lastBackup: lastBackupStatus,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/trade-config', (req, res) => {
  const status = mt5BackendStatus();
  res.json({
    ok: true,
    enabled: MT5_EXECUTION_ENABLED,
    mode: MT5_MODE,
    cliConfigured: Boolean(MT5_CLI_BIN),
    bridgeConfigured: Boolean(MT5_BRIDGE_URL),
    ready: status.ready,
    backend: status.backend || null,
    status: status.reason || 'OK',
    notes: 'Recommended default on Railway is a remote MT5 bridge, because a full local MT5 terminal does not fit the usual ~1GB memory cap.'
  });
});

app.post('/api/trade', (req, res) => {
  const trade = req.body || {};

  if (!trade || typeof trade !== 'object') {
    return res.status(400).json({ ok: false, error: 'Trade payload must be a JSON object.' });
  }

  runMt5Trade(trade, (error, result) => {
    if (error) {
      console.error('[MT5 Trade Error]', error.message || error);
      return res.status(503).json({ ok: false, error: error.message || String(error) });
    }

    return res.json({ ok: true, trade: result });
  });
});

app.get('/', (req, res) => {
  res.json({
    name: 'Hermes App (Signal Generator & Trade Analyzer)',
    status: 'running',
    tradingMode: TRADING_MODE,
    dataDir: DATA_DIR,
    lastBackup: lastBackupStatus,
    endpoints: [
      '/health',
      '/api/signals',
      '/api/analyses',
      '/api/write-data',
      '/api/read-data',
      '/api/trigger-backup'
    ]
  });
});

app.all('/api/trigger-backup', (req, res) => {
  triggerBackupScript((success, message) => {
    if (!success) {
      return res.status(500).json({ ok: false, error: message });
    }
    return res.json({ ok: true, message, status: lastBackupStatus });
  });
});

// Signals API: GET list, POST save
app.get('/api/signals', (req, res) => {
  try {
    const files = fs.readdirSync(SIGNALS_DIR).filter(f => f.endsWith('.json'));
    const limit = Number(req.query.limit) || 50;
    const signals = files
      .sort()
      .reverse()
      .slice(0, limit)
      .map(file => {
        try {
          const raw = fs.readFileSync(path.join(SIGNALS_DIR, file), 'utf8');
          return JSON.parse(raw);
        } catch (e) {
          return null;
        }
      })
      .filter(Boolean);

    res.json({ ok: true, count: signals.length, signals });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/signals', (req, res) => {
  try {
    const signalData = req.body;
    if (!signalData || typeof signalData !== 'object') {
      return res.status(400).json({ ok: false, error: 'JSON payload required' });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const id = signalData.id || `sig-${Date.now()}`;
    const filename = `signal-${timestamp}-${id}.json`;
    const targetPath = path.join(SIGNALS_DIR, filename);

    const record = {
      ...signalData,
      savedAt: new Date().toISOString()
    };

    fs.writeFileSync(targetPath, JSON.stringify(record, null, 2), 'utf8');
    res.json({ ok: true, filename, signal: record });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Trade Analyses API: GET list, POST save
app.get('/api/analyses', (req, res) => {
  try {
    const files = fs.readdirSync(ANALYSES_DIR).filter(f => f.endsWith('.json'));
    const limit = Number(req.query.limit) || 50;
    const analyses = files
      .sort()
      .reverse()
      .slice(0, limit)
      .map(file => {
        try {
          const raw = fs.readFileSync(path.join(ANALYSES_DIR, file), 'utf8');
          return JSON.parse(raw);
        } catch (e) {
          return null;
        }
      })
      .filter(Boolean);

    res.json({ ok: true, count: analyses.length, analyses });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/analyses', (req, res) => {
  try {
    const analysisData = req.body;
    if (!analysisData || typeof analysisData !== 'object') {
      return res.status(400).json({ ok: false, error: 'JSON payload required' });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const id = analysisData.analysisId || `analysis-${Date.now()}`;
    const filename = `analysis-${timestamp}-${id}.json`;
    const targetPath = path.join(ANALYSES_DIR, filename);

    const record = {
      ...analysisData,
      savedAt: new Date().toISOString()
    };

    fs.writeFileSync(targetPath, JSON.stringify(record, null, 2), 'utf8');
    res.json({ ok: true, filename, analysis: record });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
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

