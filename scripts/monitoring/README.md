# Performance Monitoring

Two agents are installed on every infrastructure host: promtail and collectd. Collectd provides metrics for prometheus, while promtail provides logs for loki. Grafana communicates with both of these services and provides means of data visualization.

Monitoring Stack:
- Data Visualization: Grafana
- Aggregation: Prometheus (metrics) and Loki (logs)
- Agents: Collectd (metrics) and Promtail (logs)


