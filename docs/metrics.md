# Metrics

## Custom contract

The collector publishes `rpi_temperature_celsius`, `rpi_cpu_frequency_hertz`, and current/since-boot pairs: `rpi_undervoltage_{now,occurred}`, `rpi_frequency_capped_{now,occurred}`, `rpi_throttled_{now,occurred}`, `rpi_soft_temperature_limit_{now,occurred}`. Boolean values are `0=OK/false`, `1=condition present/true`; frequency is Hz and temperature is Celsius.

`vcgencmd get_throttled` uses the official bitmap: bits 0..3 are current undervoltage, frequency cap, throttling, and soft-temperature-limit; bits 16..19 are the corresponding occurred-since-boot flags.

## Collector selection

The node_exporter unit explicitly enables only `cpu`, `cpufreq`, `diskstats`, `filesystem`, `loadavg`, `meminfo`, `netdev`, `netstat`, `stat`, `time`, `uname`, and `vmstat`. This is an allow-list based on the v1 dashboard and host/kernel scope, not an assumed blacklist. It avoids unrelated collectors such as hwmon, systemd, processes, textfile duplicates, and platform/storage technologies not required here.

Baseline and optimized counts must be captured on the Raspberry Pi after installation using `./scripts/verify.sh` diagnostic output. This development environment is not the target Raspberry Pi, so values are `NOT_VERIFIED` here. Record `samples`, unique metric names, `node_*`, and `rpi_*` from the diagnostic line; the baseline is obtained by temporarily running an unoptimized node_exporter and the optimized count by the checked-in unit. Disabled collectors and reasons are the allow-list inverse described above; validate any Pi-specific collector availability before changing it.
