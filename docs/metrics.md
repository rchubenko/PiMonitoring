# Metrics

## Custom contract

The collector publishes `rpi_temperature_celsius`, `rpi_cpu_frequency_hertz`, and current/since-boot pairs: `rpi_undervoltage_{now,occurred}`, `rpi_frequency_capped_{now,occurred}`, `rpi_throttled_{now,occurred}`, `rpi_soft_temperature_limit_{now,occurred}`. Boolean values are `0=OK/false`, `1=condition present/true`; frequency is Hz and temperature is Celsius.

`vcgencmd get_throttled` uses the official bitmap: bits 0..3 are current undervoltage, frequency cap, throttling, and soft-temperature-limit; bits 16..19 are the corresponding occurred-since-boot flags.

## Collector selection

The node_exporter unit explicitly enables only `cpu`, `cpufreq`, `diskstats`, `filesystem`, `hwmon`, `loadavg`, `meminfo`, `netdev`, `stat`, `textfile`, `time`, `uname`, and `vmstat`. This is an allow-list based on the dashboard and host/kernel scope, not an assumed blacklist. `netstat` was removed after the target review because the dashboard needs interface byte counters from `netdev`, not protocol statistics.

## Target hwmon discovery

The target Pi exposes these hwmon devices. Device numbering (`hwmon0`, `hwmon1`, etc.) is not used in dashboard queries.

| hwmon device | sensor label/channel | physical meaning | useful |
|---|---|---|---|
| `cpu_thermal` | `temp1` | Raspberry Pi SoC thermal zone; duplicates `rpi_temperature_celsius` | no, retained for standard host telemetry |
| `nvme` | `temp1`, label `Composite` | NVMe composite/controller temperature | yes |
| `nvme` | `temp2`, label `Sensor 1` | Additional NVMe temperature sensor; currently same value as Composite | collected, not shown in dashboard v1.x |
| `rp1_adc` | `temp1` | RP1/board thermal sensor | no for compact overview |
| `pwmfan` | no temperature channel | cooling fan device | no |
| `rpi_volt` | no temperature channel | Raspberry Pi voltage device | no |
| `hidpp_battery_0` | no temperature channel | Logitech HID++ battery | no |

node_exporter exposes the NVMe identity as `node_hwmon_chip_names{chip_name="nvme"}` and its readings as `node_hwmon_temp_celsius{sensor="temp1"}`. The dashboard joins these on `instance,chip` and selects `chip_name="nvme"`, so it does not depend on a `hwmonN` or controller index. The SoC dashboard source remains the stable `rpi_temperature_celsius` contract from `vcgencmd`; the duplicate `cpu_thermal` series is not added to the dashboard.

## Target Pi 5 measurement

The default collector process was started temporarily on `127.0.0.1:19100`; the production service was not stopped and the temporary process had no textfile directory. Counts are individual exposition samples/labelled series, not only metric names.

| configuration | samples | unique names | `node_*` | `rpi_*` |
|---|---:|---:|---:|---:|
| default/baseline | 910 | 317 | 860 | 0 |
| optimized before hwmon | 423 | 171 | 363 | 10 |
| optimized after hwmon | 457 | 185 | 397 | 10 |
| reduction from default | 453 (49.78%) | 132 (41.64%) | 463 (53.84%) | optimized adds 10 custom series |

Optimized active collectors: `cpu`, `cpufreq`, `diskstats`, `filesystem`, `hwmon`, `loadavg`, `meminfo`, `netdev`, `stat`, `textfile`, `time`, `uname`, `vmstat`. The earlier 416-sample measurement included `netstat`; after removing that unused collector and enabling `hwmon`, the final optimized count is 457.

HWMON cost relative to the pre-hwmon optimized service: `+34` samples (`+8.04%`) and `+14` unique metric names (`+8.19%`). This is considered justified because it adds standard Linux hardware visibility for the NVMe Composite temperature while retaining the existing low-cardinality allow-list. The additional `Sensor 1`, SoC duplicate, and RP1 readings remain collected for host diagnostics but are intentionally not added to the compact dashboard.

Default collectors disabled and reason: `arp` (not needed), `bcache` (no bcache), `bcachefs` (not used), `bonding` (no bonded interfaces), `btrfs` (root is ext4), `conntrack` (no firewall telemetry in scope), `dmi` (not useful on Pi), `dmmultipath` (no multipath), `edac` (not applicable to this Pi), `entropy` (not dashboard scope), `fibrechannel` (no Fibre Channel), `filefd` (not process/FD scope), `infiniband` (no device), `ipvs` (no IPVS), `kernel_hung` (not v1 scope), `mdadm` (no RAID), `netclass` (interface metadata not needed), `netstat` (unused after review), `nfs` and `nfsd` (not used), `nvme` (diskstats already provides required NVMe I/O), `os` (uname is sufficient for v1), `powersupplyclass` (no required power telemetry), `pressure` (not in dashboard scope), `rapl` (not supported on Pi), `schedstat` (not required), `selinux` (not enabled/scope), `sockstat` (not required), `softnet` (not required), `tapestats` (no tape), `thermal_zone` (standard thermal data is duplicated by the custom vcgencmd contract), `timex` (not required), `udp_queues` (not required), `watchdog` (not required), `xfs` and `zfs` (root/storage are not these filesystems). `hwmon` and `textfile` are explicitly enabled.
