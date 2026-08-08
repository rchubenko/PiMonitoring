#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { printf 'ERROR: run as root\n' >&2; exit 1; }
command -v vcgencmd >/dev/null || { printf 'ERROR: vcgencmd is required on Raspberry Pi OS\n' >&2; exit 1; }
getent group video >/dev/null || { printf 'ERROR: video group is required for vcgencmd access\n' >&2; exit 1; }
id pi-metrics &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin --gid video pi-metrics
install -d -o pi-metrics -g node-exp -m 0755 /var/lib/node_exporter/textfile_collector
chown pi-metrics:node-exp /var/lib/node_exporter/textfile_collector
chmod 0755 /var/lib/node_exporter/textfile_collector
usermod -a -G node-exp pi-metrics
install -o root -g root -m 0755 exporters/rpi-metrics.sh /usr/local/libexec/pi-monitoring-rpi-metrics
install -o root -g root -m 0644 systemd/rpi-metrics.service /etc/systemd/system/rpi-metrics.service
install -o root -g root -m 0644 systemd/rpi-metrics.timer /etc/systemd/system/rpi-metrics.timer
systemctl daemon-reload
systemctl enable --now rpi-metrics.timer
systemctl start rpi-metrics.service
printf 'rpi-metrics installed and executed once\n'
