#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { printf 'ERROR: run as root\n' >&2; exit 1; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'ERROR: Debian trixie is required\n' >&2; exit 1; }
[[ $(dpkg --print-architecture) == arm64 ]] || { printf 'ERROR: Debian arm64 is required\n' >&2; exit 1; }
apt-get update
apt-get install -y ca-certificates curl gnupg
install -d -m 0755 /etc/apt/keyrings
curl --fail --silent --show-error --location https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod 0644 /etc/apt/keyrings/docker.gpg
printf 'deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable\n' > /etc/apt/sources.list.d/docker.list
apt-get update
DOCKER_VERSION=5:29.7.2-1~debian.13~trixie
apt-cache madison docker-ce | grep -F "$DOCKER_VERSION" >/dev/null || { printf 'ERROR: pinned Docker version %s is not available in the repository\n' "$DOCKER_VERSION" >&2; exit 1; }
apt-get install -y "docker-ce=$DOCKER_VERSION" "docker-ce-cli=$DOCKER_VERSION" containerd.io docker-buildx-plugin docker-compose-plugin
apt-mark hold docker-ce docker-ce-cli
systemctl enable --now docker
printf 'Docker Engine %s installed\n' "$DOCKER_VERSION"
