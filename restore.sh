#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" ]]; then
    echo "FAIL: backup file argument is required" >&2
    echo "Usage: ./restore.sh <backup.sql>" >&2
    exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "FAIL: backup file does not exist: $BACKUP_FILE" >&2
    exit 1
fi

if [[ ! -s "$BACKUP_FILE" ]]; then
    echo "FAIL: backup file is empty: $BACKUP_FILE" >&2
    exit 1
fi

if ! sudo docker inspect -f '{{.State.Running}}' postgres 2>/dev/null | grep -qx true; then
    echo "FAIL: postgres container is not running" >&2
    exit 1
fi

echo "Restoring PostgreSQL database from: $BACKUP_FILE"

if ! sudo docker exec -i postgres psql -U barq_app -d barq_tasks < "$BACKUP_FILE"; then
    echo "FAIL: PostgreSQL restore failed" >&2
    exit 1
fi

echo "PASS: PostgreSQL restore completed successfully"
