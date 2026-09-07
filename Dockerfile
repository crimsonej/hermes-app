FROM node:20-bookworm-slim

ARG HERMES_VERSION=v2026.8.31

RUN apt-get update \
	&& apt-get install -y --no-install-recommends bash ca-certificates curl git openssl python3.11 python3.11-venv \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -LsSf https://astral.sh/uv/install.sh | sh \
	&& /root/.local/bin/uv python install 3.11

ENV PATH="/root/.local/bin:/root/.hermes/bin:${PATH}"
ENV HERMES_HOME=/app/.hermes
ENV PORT=3000 \
	DATA_DIR=/app/data \
	RESTORE_ON_START=true \
	HERMES_ENABLED=true \
	HERMES_TRADING_MODE=paper \
	LIVE_TRADING_ENABLED=false \
	BACKUP_BRANCH=main \
	BACKUP_REPO=crimsonej/hermes-app-backup

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

RUN git clone --depth 1 --branch "${HERMES_VERSION}" https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent \
	&& /root/.local/bin/uv venv /opt/hermes-venv --python 3.11 \
	&& /root/.local/bin/uv pip install --python /opt/hermes-venv/bin/python -e /opt/hermes-agent

EXPOSE 3000

CMD ["bash", "scripts/start.sh"]
