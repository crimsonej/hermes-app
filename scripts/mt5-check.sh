#!/usr/bin/env bash
set -euo pipefail

if [ "${MT5_EXECUTION_ENABLED:-false}" != "true" ]; then
  echo "MT5 live trading is disabled. No backend validation required."
  exit 0
fi

if [ -n "${MT5_BRIDGE_URL:-}" ]; then
  python3 - "${MT5_BRIDGE_URL}" <<'PY'
import sys
from urllib.parse import urlparse

url = sys.argv[1]
parsed = urlparse(url)
if parsed.scheme not in ("http", "https") or not parsed.netloc:
    raise SystemExit(f"Invalid MT5 bridge URL: {url}")
print(f"MT5 bridge URL is valid: {url}")
PY
  exit 0
fi

if [ -n "${MT5_CLI_BIN:-}" ]; then
  if [ ! -x "${MT5_CLI_BIN}" ]; then
    echo "ERROR: MT5_CLI_BIN is set but the file is not executable: ${MT5_CLI_BIN}" >&2
    exit 1
  fi
  echo "MT5 CLI binary is present and executable: ${MT5_CLI_BIN}"
  exit 0
fi

echo "ERROR: MT5 live trading is enabled but no valid MT5 backend is configured. Set MT5_BRIDGE_URL or MT5_CLI_BIN." >&2
exit 1
