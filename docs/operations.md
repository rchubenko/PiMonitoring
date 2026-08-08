# Operations

Run `sudo ./scripts/deploy.sh` to idempotently recreate/update the Compose services. Use `docker compose ps`, `docker compose logs --tail=100 prometheus`, and `docker compose logs --tail=100 grafana` for container troubleshooting. Do not remove `/srv/monitoring` when redeploying.

Manage host components with `systemctl status node-exporter rpi-metrics.timer`, `systemctl restart node-exporter`, and `systemctl start rpi-metrics.service`. The timer runs 15 seconds after boot and every 15 seconds without catch-up.

Upgrade by reviewing upstream stable releases, changing the pinned value and checksum/image tag in Git, validating configuration, then running the installers/deploy. Back up the two persistent directories before upgrades. Common failures are missing `vcgencmd`, missing `video` permissions, a missing `.env`, or a Docker repository version no longer being available.
