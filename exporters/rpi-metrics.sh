#!/usr/bin/env bash
set -Eeuo pipefail

OUT=${RPI_METRICS_OUTPUT:-/var/lib/node_exporter/textfile_collector/rpi.prom}
tmp=$(mktemp "${OUT}.tmp.XXXXXX")
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT

command -v vcgencmd >/dev/null || { printf 'ERROR: vcgencmd not found\n' >&2; exit 1; }
command -v awk >/dev/null || { printf 'ERROR: awk not found\n' >&2; exit 1; }

temperature=$(vcgencmd measure_temp | awk -F"=|'" 'NF >= 2 && $2 ~ /^[0-9]+([.][0-9]+)?$/ { print $2; found=1 } END { if (!found) exit 1 }')
frequency=$(vcgencmd measure_clock arm | awk -F'=' '$2 ~ /^[0-9]+$/ { print $2; found=1 } END { if (!found) exit 1 }')
throttled=$(vcgencmd get_throttled | awk -F= '$2 ~ /^0x[0-9a-fA-F]+$/ { print $2; found=1 } END { if (!found) exit 1 }')
value=$((throttled))

bit() { if (( (value & (1 << $1)) != 0 )); then printf '1'; else printf '0'; fi; }

{
  printf '# HELP rpi_temperature_celsius Raspberry Pi SoC temperature in Celsius.\n# TYPE rpi_temperature_celsius gauge\nrpi_temperature_celsius %s\n' "$temperature"
  printf '# HELP rpi_cpu_frequency_hertz Current ARM CPU frequency in Hertz.\n# TYPE rpi_cpu_frequency_hertz gauge\nrpi_cpu_frequency_hertz %s\n' "$frequency"
  printf '# HELP rpi_undervoltage_now Undervoltage is currently present (0=OK, 1=active).\n# TYPE rpi_undervoltage_now gauge\nrpi_undervoltage_now %s\n' "$(bit 0)"
  printf '# HELP rpi_undervoltage_occurred Undervoltage has occurred since boot (0=no, 1=yes).\n# TYPE rpi_undervoltage_occurred gauge\nrpi_undervoltage_occurred %s\n' "$(bit 16)"
  printf '# HELP rpi_frequency_capped_now Frequency is currently capped (0=OK, 1=active).\n# TYPE rpi_frequency_capped_now gauge\nrpi_frequency_capped_now %s\n' "$(bit 1)"
  printf '# HELP rpi_frequency_capped_occurred Frequency capping has occurred since boot (0=no, 1=yes).\n# TYPE rpi_frequency_capped_occurred gauge\nrpi_frequency_capped_occurred %s\n' "$(bit 17)"
  printf '# HELP rpi_throttled_now Throttling is currently active (0=OK, 1=active).\n# TYPE rpi_throttled_now gauge\nrpi_throttled_now %s\n' "$(bit 2)"
  printf '# HELP rpi_throttled_occurred Throttling has occurred since boot (0=no, 1=yes).\n# TYPE rpi_throttled_occurred gauge\nrpi_throttled_occurred %s\n' "$(bit 18)"
  printf '# HELP rpi_soft_temperature_limit_now Soft temperature limit is currently active (0=OK, 1=active).\n# TYPE rpi_soft_temperature_limit_now gauge\nrpi_soft_temperature_limit_now %s\n' "$(bit 3)"
  printf '# HELP rpi_soft_temperature_limit_occurred Soft temperature limit has occurred since boot (0=no, 1=yes).\n# TYPE rpi_soft_temperature_limit_occurred gauge\nrpi_soft_temperature_limit_occurred %s\n' "$(bit 19)"
} > "$tmp"
chmod 0644 "$tmp"
mv -f -- "$tmp" "$OUT"
trap - EXIT
