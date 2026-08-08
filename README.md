# PiMonitoring

PiMonitoring is a small reproducible monitoring stack for an always-on Raspberry Pi 5. Host metrics run natively through node_exporter and a minimal `vcgencmd` textfile collector. Prometheus and Grafana run in Docker Compose.

## Pinned versions

- Docker Engine `29.7.2` (`5:29.7.2-1~debian.13~trixie`)
- node_exporter `1.12.1`
- Prometheus `3.13.2`
- Grafana `13.1.3`

These are stable upstream releases checked on 2026-08-08. Images use exact tags; standalone node_exporter is SHA256 checked against the upstream release checksum file.

## Install and deploy

Target is Debian 13 Trixie ARM64. Run as root:

```sh
sudo ./scripts/install-docker.sh
sudo ./scripts/install-node-exporter.sh
sudo ./scripts/install-rpi-metrics.sh
cp .env.example .env
# Set a long random GF_SECURITY_ADMIN_PASSWORD in .env
sudo ./scripts/deploy.sh
sudo ./scripts/verify.sh
```

Prometheus is at `http://127.0.0.1:9090`, Grafana at `http://127.0.0.1:3000`. Grafana authentication is enabled and anonymous access is disabled. Persistent data is in `/srv/monitoring/prometheus` and `/srv/monitoring/grafana`.

Edit `grafana/dashboards/raspberry-pi-overview.json` and rerun `deploy.sh`; file provisioning checks it every 30 seconds. The dashboard can also be edited and saved in Grafana UI. A later file-provisioning update may overwrite UI edits by design.

Netdata is intentionally not managed, removed, or configured by this repository.
