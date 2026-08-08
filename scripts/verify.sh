#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); cd "$ROOT"
fail=0
[[ -f .env ]] || { printf 'ERROR: .env is required; copy .env.example and set the password\n' >&2; exit 1; }
ok() { printf 'OK   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }
check() { if "$@" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
check /usr/local/bin/node_exporter --version
check systemctl is-active --quiet node-exporter.service
check curl -fsS http://127.0.0.1:9100/metrics
check systemctl is-active --quiet rpi-metrics.timer
check sudo systemctl start rpi-metrics.service
[[ -s /var/lib/node_exporter/textfile_collector/rpi.prom ]] && ok 'rpi.prom exists' || bad 'rpi.prom exists'
required=(rpi_temperature_celsius rpi_cpu_frequency_hertz rpi_undervoltage_now rpi_undervoltage_occurred rpi_frequency_capped_now rpi_frequency_capped_occurred rpi_throttled_now rpi_throttled_occurred rpi_soft_temperature_limit_now rpi_soft_temperature_limit_occurred)
for metric in "${required[@]}"; do grep -Eq "^${metric}([ {]|$)" /var/lib/node_exporter/textfile_collector/rpi.prom && ok "$metric in textfile" || bad "$metric in textfile"; done
check curl -fsS http://127.0.0.1:9100/metrics
for metric in "${required[@]}"; do curl -fsS http://127.0.0.1:9100/metrics | grep -Eq "^${metric}([ {]|$)" && ok "$metric in node_exporter" || bad "$metric in node_exporter"; done
check docker info
check docker compose version
check docker compose ps --status running prometheus
check docker compose ps --status running grafana
check curl -fsS http://127.0.0.1:9090/-/healthy
check docker compose exec -T prometheus promtool check config /etc/prometheus/prometheus.yml
curl -fsS http://127.0.0.1:9090/api/v1/targets | grep -q '"health":"up"' && ok 'Prometheus node target UP' || bad 'Prometheus node target UP'
curl -fsS 'http://127.0.0.1:9090/api/v1/query?query=rpi_temperature_celsius' | grep -q '"success"' && ok 'rpi metric queryable' || bad 'rpi metric queryable'
check curl -fsS http://127.0.0.1:3000/api/health
source .env
auth="admin:${GF_SECURITY_ADMIN_PASSWORD}"
curl -fsS -u "$auth" http://127.0.0.1:3000/api/dashboards/uid/raspberry-pi-overview | grep -q 'raspberry-pi-overview' && ok 'Grafana dashboard UID raspberry-pi-overview' || bad 'Grafana dashboard'
curl -fsS -u "$auth" http://127.0.0.1:3000/api/datasources/uid/prometheus | grep -q '"uid":"prometheus"' && ok 'Grafana datasource UID prometheus' || bad 'Grafana datasource'
samples=$(curl -fsS http://127.0.0.1:9100/metrics | awk '!/^#/ && NF {n++} END {print n+0}')
names=$(curl -fsS http://127.0.0.1:9100/metrics | awk '!/^#/ && NF {sub(/[{ ].*/, "", $1); print $1}' | sort -u | wc -l)
node=$(curl -fsS http://127.0.0.1:9100/metrics | awk '!/^#/ && /^node_/ {n++} END {print n+0}')
rpi=$(curl -fsS http://127.0.0.1:9100/metrics | awk '!/^#/ && /^rpi_/ {n++} END {print n+0}')
printf 'DIAG samples=%s unique_names=%s node_samples=%s rpi_samples=%s\n' "$samples" "$names" "$node" "$rpi"
(( fail == 0 )) && { printf 'PASS\n'; exit 0; } || { printf 'FAIL\n'; exit 1; }
