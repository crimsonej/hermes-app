FROM node:20-bookworm-slim

ARG HERMES_VERSION=v2026.8.31
ARG INSTALL_FULL_STACK=false

# 1. Install only the dependencies needed for a memory-safe Railway runtime by default.
#    Full browser/ML tooling can be enabled with: --build-arg INSTALL_FULL_STACK=true
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git git-lfs openssl sudo \
    build-essential gcc g++ gfortran make cmake ninja-build pkg-config libssl-dev libffi-dev \
    jq unzip zip tar gzip bzip2 xz-utils zstd \
    procps psmisc lsof tree htop ncdu ripgrep fd-find tmux screen vim nano less \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    sqlite3 libsqlite3-dev \
    net-tools iputils-ping dnsutils iproute2 nmap netcat-openbsd traceroute rsync strace \
    libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
    libxrandr2 libxrender1 libxtst6 libnss3 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libgbm1 libasound2 \
    libgtk-3-0 libpangocairo-1.0-0 libpango-1.0-0 \
    xvfb \
    && echo "ALL ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopasswd \
    && chmod 0440 /etc/sudoers.d/nopasswd \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /root/.local/bin/uv python install 3.11 \
    && if [ "$INSTALL_FULL_STACK" = "true" ]; then \
         apt-get update && apt-get install -y --no-install-recommends ffmpeg tesseract-ocr tesseract-ocr-eng poppler-utils chromium && rm -rf /var/lib/apt/lists/*; \
       fi

# 2. Configure a lean default environment intended for Railway's ~1GB memory ceiling.
ENV PATH="/opt/hermes-venv/bin:/root/.local/bin:/root/.hermes/bin:/usr/local/bin:/usr/bin:${PATH}" \
    HERMES_HOME=/app/.hermes \
    HERMES_PROFILE=lean \
    ENABLE_XVFB=false \
    MT5_MODE=bridge \
    MT5_EXECUTION_ENABLED=false \
    MT5_BRIDGE_URL="" \
    MT5_CLI_BIN="" \
    PORT=3000 \
    DATA_DIR=/app/data \
    RESTORE_ON_START=true \
    HERMES_ENABLED=true \
    HERMES_TRADING_MODE=paper \
    LIVE_TRADING_ENABLED=false \
    BACKUP_BRANCH=main \
    BACKUP_REPO=crimsonej/hermes-app-backup \
    OPENAI_API_BASE=https://integrate.api.nvidia.com/v1 \
    AUTO_BACKUP_HOURS=24 \
    TELEGRAM_BOT_TOKEN="" \
    TELEGRAM_CHAT_ID="" \
    HERMES_ACCEPT_HOOKS=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    SHELL=/bin/bash \
    CHROME_BIN=/usr/bin/chromium \
    CHROMIUM_PATH=/usr/bin/chromium \
    CHROMIUM_FLAGS="--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu --disable-extensions --disable-background-networking --disable-sync --disable-default-apps --no-first-run --disable-background-timer-throttling --disable-renderer-backgrounding --disable-features=TranslateUI --disable-ipc-flooding-protection" \
    DISPLAY=:99

WORKDIR /app

# 3. Create runtime & system directories
RUN mkdir -p /app/data/signals /app/data/analyses /app/.hermes/skills /app/backups /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# 4. Install Node dependencies without the heavyweight browser automation stack by default.
COPY package*.json ./
RUN npm install --omit=dev && if [ "$INSTALL_FULL_STACK" = "true" ]; then npm install -g agent-browser playwright || true; fi

# 5. Copy application files
COPY . .

# 6. Copy skills, SOUL, and AGENTS to Hermes home
RUN cp -R hermes/skills/. /app/.hermes/skills/ 2>/dev/null || true \
    && cp hermes/SOUL.md /app/.hermes/SOUL.md 2>/dev/null || true \
    && cp hermes/AGENTS.md /app/.hermes/AGENTS.md 2>/dev/null || true

# 7. Install Hermes Agent plus only the core package set needed for signal processing.
#    Full browser/ML packages remain opt-in via INSTALL_FULL_STACK=true.
RUN git clone --depth 1 --branch "${HERMES_VERSION}" https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent \
    && /root/.local/bin/uv venv /opt/hermes-venv --python 3.11 \
    && /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python -e /opt/hermes-agent \
    && /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python \
       ccxt pandas numpy requests httpx aiohttp websocket-client websockets urllib3 \
       pyyaml pydantic python-dotenv openpyxl \
       beautifulsoup4 lxml duckduckgo-search ddgs \
       asyncpg psycopg2-binary redis \
    && if [ "$INSTALL_FULL_STACK" = "true" ]; then \
         /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python \
           ta pandas-ta polars duckdb yfinance scipy scikit-learn statsmodels playwright selenium \
           gTTS edge-tts pillow pytesseract; \
         /opt/hermes-venv/bin/python -m playwright install chromium || true; \
       fi \
    && ln -sf /opt/hermes-venv/bin/hermes /usr/local/bin/hermes

# 8. Healthcheck endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

# 9. Start Xvfb + Hermes gateway + web server in the lean profile by default.
CMD ["bash", "scripts/start.sh"]