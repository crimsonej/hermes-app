#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up full Hermes environment..."

# 1. System packages (from Dockerfile)
echo "📦 Installing system packages..."
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git git-lfs openssl sudo \
    build-essential gcc g++ gfortran make cmake ninja-build pkg-config libssl-dev libffi-dev \
    jq unzip zip tar gzip bzip2 xz-utils zstd \
    procps psmisc lsof tree htop ncdu ripgrep fd-find tmux screen vim nano less \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    sqlite3 libsqlite3-dev \
    net-tools iputils-ping dnsutils iproute2 nmap netcat-openbsd traceroute rsync strace \
    ffmpeg tesseract-ocr tesseract-ocr-eng poppler-utils \
    libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
    libxrandr2 libxrender1 libxtst6 libnss3 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libgbm1 libasound2 \
    libgtk-3-0 libpangocairo-1.0-0 libpango-1.0-0 \
    xvfb chromium \
    && sudo rm -rf /var/lib/apt/lists/*

# 2. Install uv (Python package manager)
echo "🐍 Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# 3. Install Python 3.11 via uv
echo "🐍 Installing Python 3.11..."
uv python install 3.11

# 4. Create Hermes virtual environment (needs sudo for /opt)
echo "🏗️ Creating Hermes venv at /opt/hermes-venv..."
sudo uv venv /opt/hermes-venv --python 3.11

# 5. Clone Hermes agent
echo "📥 Cloning Hermes agent..."
HERMES_VERSION="v2026.8.31"
sudo git clone --depth 1 --branch "${HERMES_VERSION}" https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 6. Install Hermes + all Python dependencies
echo "📚 Installing Hermes agent and dependencies..."
sudo /home/joa/.local/bin/uv pip install --python /opt/hermes-venv/bin/python -e /opt/hermes-agent
sudo /home/joa/.local/bin/uv pip install --python /opt/hermes-venv/bin/python \
    ccxt pandas numpy ta pandas-ta polars duckdb yfinance scipy scikit-learn statsmodels \
    httpx aiohttp websockets requests urllib3 \
    pyyaml pydantic python-dotenv openpyxl \
    beautifulsoup4 lxml duckduckgo-search ddgs \
    playwright selenium \
    gTTS edge-tts pillow pytesseract \
    asyncpg psycopg2-binary redis

# 7. Symlink hermes binary
echo "🔗 Linking hermes binary..."
sudo ln -sf /opt/hermes-venv/bin/hermes /usr/local/bin/hermes

# 8. Create runtime directories
echo "📁 Creating runtime directories..."
sudo mkdir -p /app/data/signals /app/data/analyses /app/.hermes/skills /app/backups

# 9. Copy local skills, SOUL.md, and AGENTS.md to Hermes home
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "$ROOT_DIR/hermes/skills" ]; then
    sudo cp -R "$ROOT_DIR/hermes/skills/." /app/.hermes/skills/
    echo "✅ Copied custom skills to /app/.hermes/skills/"
fi
if [ -f "$ROOT_DIR/hermes/SOUL.md" ]; then
    sudo cp "$ROOT_DIR/hermes/SOUL.md" /app/.hermes/SOUL.md
fi
if [ -f "$ROOT_DIR/hermes/AGENTS.md" ]; then
    sudo cp "$ROOT_DIR/hermes/AGENTS.md" /app/.hermes/AGENTS.md
fi

# 10. Verify installation
echo "✅ Verifying installation..."
/opt/hermes-venv/bin/hermes --version
/opt/hermes-venv/bin/hermes doctor --check system

echo ""
echo "🎉 Full Hermes environment ready!"
echo "   Run: hermes doctor --check system"
echo "   Then: export PATH=\"/opt/hermes-venv/bin:\$PATH\""