FROM node:20-bookworm-slim

ARG HERMES_VERSION=v2026.8.31

# Install comprehensive Linux utilities, build tools, compiler suites, and CLI tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    openssl \
    build-essential \
    gcc \
    g++ \
    make \
    jq \
    unzip \
    tar \
    gzip \
    procps \
    psmisc \
    lsof \
    tree \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /root/.local/bin/uv python install 3.11

# Environment variables setup
ENV PATH="/opt/hermes-venv/bin:/root/.local/bin:/root/.hermes/bin:${PATH}" \
    HERMES_HOME=/app/.hermes \
    PORT=3000 \
    DATA_DIR=/app/data \
    RESTORE_ON_START=true \
    HERMES_ENABLED=true \
    HERMES_TRADING_MODE=paper \
    LIVE_TRADING_ENABLED=false \
    BACKUP_BRANCH=main \
    BACKUP_REPO=crimsonej/hermes-app-backup \
    OPENAI_API_BASE=https://integrate.api.nvidia.com/v1 \
    AUTO_BACKUP_HOURS=24

WORKDIR /app

# Ensure runtime directories exist
RUN mkdir -p /app/data /app/data/signals /app/data/analyses /app/.hermes /app/backups

# Install Node.js dependencies
COPY package*.json ./
RUN npm install --omit=dev

# Copy application files
COPY . .

# Clone & install Hermes Agent + Trading & Analysis Python packages (ccxt, pandas, ta, websockets, httpx, etc.)
RUN git clone --depth 1 --branch "${HERMES_VERSION}" https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent \
    && /root/.local/bin/uv venv /opt/hermes-venv --python 3.11 \
    && /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python -e /opt/hermes-agent \
    && /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python \
       ccxt \
       pandas \
       numpy \
       ta \
       httpx \
       aiohttp \
       websockets \
       pyyaml \
       pydantic \
       python-dotenv \
       beautifulsoup4 \
       lxml \
    && ln -sf /opt/hermes-venv/bin/hermes /usr/local/bin/hermes

EXPOSE 3000

CMD ["bash", "scripts/start.sh"]
