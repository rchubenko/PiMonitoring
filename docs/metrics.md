# Metrics

## Custom contract

The collector publishes `rpi_temperature_celsius`, `rpi_cpu_frequency_hertz`, and current/since-boot pairs: `rpi_undervoltage_{now,occurred}`, `rpi_frequency_capped_{now,occurred}`, `rpi_throttled_{now,occurred}`, `rpi_soft_temperature_limit_{now,occurred}`. Boolean values are `0=OK/false`, `1=condition present/true`; frequency is Hz and temperature is Celsius.

`vcgencmd get_throttled` uses the official bitmap: bits 0..3 are current undervoltage, frequency cap, throttling, and soft-temperature-limit; bits 16..19 are the corresponding occurred-since-boot flags.

## Collector selection

The node_exporter unit explicitly enables only `cpu`, `cpufreq`, `diskstats`, `filesystem`, `loadavg`, `meminfo`, `netdev`, `stat`, `textfile`, `time`, `uname`, and `vmstat`. This is an allow-list based on the v1 dashboard and host/kernel scope, not an assumed blacklist. `netstat` was removed after the target review because the dashboard needs interface byte counters from `netdev`, not protocol statistics.

## Target Pi 5 measurement

The default collector process was started temporarily on `127.0.0.1:19100`; the production service was not stopped and the temporary process had no textfile directory. Counts are individual exposition samples/labelled series, not only metric names.

| configuration | samples | unique names | `node_*` | `rpi_*` |
|---|---:|---:|---:|---:|
| default/baseline | 910 | 317 | 860 | 0 |
| optimized | 423 | 171 | 363 | 10 |
| reduction | 487 (53.52%) | 146 (46.06%) | 497 (57.79%) | optimized adds 10 custom series |

Optimized active collectors: `cpu`, `cpufreq`, `diskstats`, `filesystem`, `loadavg`, `meminfo`, `netdev`, `stat`, `textfile`, `time`, `uname`, `vmstat`. The earlier 416-sample measurement included `netstat`; after removing that unused collector and measuring with the deployed Docker network interfaces present, the final optimized count is 423.

Default collectors disabled and reason: `arp` (not needed), `bcache` (no bcache), `bcachefs` (not used), `bonding` (no bonded interfaces), `btrfs` (root is ext4), `conntrack` (no firewall telemetry in scope), `dmi` (not useful on Pi), `dmmultipath` (no multipath), `edac` (not applicable to this Pi), `entropy` (not dashboard scope), `fibrechannel` (no Fibre Channel), `filefd` (not process/FD scope), `hwmon` (custom vcgencmd contract), `infiniband` (no device), `ipvs` (no IPVS), `kernel_hung` (not v1 scope), `mdadm` (no RAID), `netclass` (interface metadata not needed), `netstat` (unused after review), `nfs` and `nfsd` (not used), `nvme` (diskstats already provides required NVMe I/O), `os` (uname is sufficient for v1), `powersupplyclass` (no required power telemetry), `pressure` (not in dashboard scope), `rapl` (not supported on Pi), `schedstat` (not required), `selinux` (not enabled/scope), `sockstat` (not required), `softnet` (not required), `tapestats` (no tape), `thermal_zone` (custom vcgencmd temperature is the stable contract), `timex` (not required), `udp_queues` (not required), `watchdog` (not required), `xfs` and `zfs` (root/storage are not these filesystems). `textfile` is explicitly enabled and is not disabled.
