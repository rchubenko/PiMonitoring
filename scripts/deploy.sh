#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
[[ -f .env ]] || { printf 'ERROR: create .env from .env.example first\n' >&2; exit 1; }
command -v docker >/dev/null || { printf 'ERROR: Docker is not installed\n' >&2; exit 1; }
install -d -o 65534 -g 65534 -m 0750 /srv/monitoring/prometheus
install -d -o 472 -g 472 -m 0750 /srv/monitoring/grafana
docker compose config >/dev/null
docker compose up -d
printf 'PiMonitoring deployed. Prometheus: http://127.0.0.1:9090 Grafana: http://127.0.0.1:3000\n'
