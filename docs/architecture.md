# Architecture

The deployment is hybrid. `node_exporter` and `rpi-metrics` run on the host under systemd. Prometheus and Grafana run as Compose services. Prometheus reaches the host exporter through Docker's `host.docker.internal` gateway mapping, without depending on a DHCP address.

Data flow: `vcgencmd -> rpi.prom -> node_exporter:9100 -> Prometheus -> Grafana`. Prometheus stores data in `/srv/monitoring/prometheus`; Grafana stores its database in `/srv/monitoring/grafana`. Both UI ports bind to loopback only.

The `job` label is stable (`node`) and the `instance` dashboard variable makes additional exporters/machines possible later. The structure leaves room for alerting, logs, or other exporters without changing this foundation, but none are part of v1.
