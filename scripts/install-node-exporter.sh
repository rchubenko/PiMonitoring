#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

NODE_EXPORTER_VERSION=1.12.1
ARCHIVE="node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${ARCHIVE}"
SUM_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/sha256sums.txt"
[[ $EUID -eq 0 ]] || { printf 'ERROR: run as root\n' >&2; exit 1; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'ERROR: Debian trixie is required\n' >&2; exit 1; }
[[ $(uname -m) == aarch64 ]] || { printf 'ERROR: target architecture must be aarch64\n' >&2; exit 1; }

id node-exp &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin node-exp
install -d -o root -g node-exp -m 0770 /var/lib/node_exporter/textfile_collector
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl --fail --silent --show-error --location "$URL" -o "$tmp/$ARCHIVE"
curl --fail --silent --show-error --location "$SUM_URL" -o "$tmp/sha256sums.txt"
(cd "$tmp" && grep "  $ARCHIVE$" sha256sums.txt | sha256sum -c -)
tar -xzf "$tmp/$ARCHIVE" -C "$tmp"
install -o root -g root -m 0755 "$tmp/node_exporter-${NODE_EXPORTER_VERSION}/node_exporter" /usr/local/bin/node_exporter
install -o root -g root -m 0644 "$(dirname "$0")/../systemd/node-exporter.service" /etc/systemd/system/node-exporter.service
systemctl daemon-reload
systemctl enable --now node-exporter.service
printf 'node_exporter %s installed\n' "$NODE_EXPORTER_VERSION"
