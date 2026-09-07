FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HERMES_DATA_DIR=/data/hermes \
    BACKUP_WORK_DIR=/tmp/backup-work

RUN apt-get update \
    && apt-get install -y --no-install-recommends git gnupg ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY entrypoint.sh backup.sh restore.sh /app/
RUN chmod +x /app/entrypoint.sh /app/backup.sh /app/restore.sh \
    && mkdir -p /data/hermes /tmp/backup-work

COPY . /app/project/

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
