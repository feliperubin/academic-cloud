#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Configure grafana, adding prometheus as its datasource


# You can change it when login in for the first time for now..
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

while [ $# -gt 0 ]; do
  case "$1" in
    --time) shift; PROMETHEUS_DEFAULT_INTERVAL="$1"; shift;;
    --prometheus) shift; PROMETHEUS_IP="$1"; shift;;
    --loki) shift; LOKI_IP="$1"; shift;;
    *) echo "Unknown Parameter $1, exiting..."; exit 1;;
  esac
done


if [ -z "$PROMETHEUS_DEFAULT_INTERVAL" ]; then
PROMETHEUS_DEFAULT_INTERVAL="60s"
fi
if [ -z "$PROMETHEUS_IP" ]; then
  PROMETHEUS_IP="127.0.0.1:9090"
fi
if [ -z "$LOKI_IP" ]; then
LOKI_IP="127.0.0.1:3100"
fi
# if [ -z "$" ]; then
# fi


# More info here
# https://grafana.com/docs/grafana/latest/administration/provisioning/

sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Alternatively you can add the beta repository, see in the table above
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

sudo apt-get update
sudo apt-get install -y grafana
sudo systemctl stop grafana-server

# Bootstrap

cat >> /etc/grafana/grafana.ini <<EOF
[security]
admin_user = $GRAFANA_USER
admin_password = $GRAFANA_PASS
EOF

# Create a new  new datasource
cat > /etc/grafana/provisioning/datasources/infrastructure.yml <<EOF
# config file version
apiVersion: 1

# Delete the first datasource
deleteDatasources:
  - name: Graphite
    orgId: 1

# Prometheus Datasource
datasources:
  - name: Prometheus
    type: prometheus
    url: http://$PROMETHEUS_IP
    basicAuth: false
    orgId: 1
    isDefault: true
    access: proxy
    version: 1
    editable: true
    uuid: prometheus_infra_uuid
    jsonData:
      timeInterval: "$PROMETHEUS_DEFAULT_INTERVAL"
  - name: Loki
    type: loki
    access: proxy
    url: http://$LOKI_IP
    basicAuth: false
    uuid: loki_infra_uuid
    orgId: 1
    editable: true
    jsonData:
      maxLines: 1000
EOF

#######

cat > /etc/grafana/provisioning/dashboards/infra.yml <<EOF
---
apiVersion: 1

providers:
  # <string> an unique provider name. Required
  - name: 'Infrastructure'
    # <int> Org id. Default to 1
    orgId: 1
    # <string> name of the dashboard folder.
    folder: 'infrastructure'
    # <string> folder UID. will be automatically generated if not specified
    folderUid: ''
    # <string> provider type. Default to 'file'
    type: file
    # <bool> disable dashboard deletion
    disableDeletion: false
    # <bool> enable dashboard editing
    editable: true
    # <int> how often Grafana will scan for changed dashboards
    updateIntervalSeconds: 10
    # <bool> allow updating provisioned dashboards from the UI
    allowUiUpdates: true
    options:
      # <string, required> path to dashboard files on disk. Required when using the 'file' type
      path: /var/lib/grafana/dashboards
EOF
# Create Folder
mkdir /var/lib/grafana/dashboards

cat > /var/lib/grafana/dashboards/infrastructure.json << EOF
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 3,
  "links": [],
  "panels": [
    {
      "datasource": null,
      "description": "The use of allocated processing power.",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 85
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 8,
        "x": 0,
        "y": 0
      },
      "id": 4,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": false
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "100 * (1 - sum(collectd_cpu_total{type=\"idle\"}) by (exported_instance) / sum(collectd_cpu_total) by (exported_instance))",
          "interval": "",
          "legendFormat": "{{exported_instance}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "CPU Load",
      "type": "gauge"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": null,
      "description": "Short Term Load",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 10,
      "gridPos": {
        "h": 9,
        "w": 16,
        "x": 8,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 8,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": false,
        "min": false,
        "rightSide": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null as zero",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": true,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "collectd_load_shortterm",
          "instant": false,
          "interval": "",
          "legendFormat": "{{exported_instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "gt",
          "value": 0.95,
          "yaxis": "left"
        },
        {
          "colorMode": "warning",
          "fill": true,
          "line": true,
          "op": "gt",
          "value": 0.8,
          "yaxis": "left"
        }
      ],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Resource Load",
      "tooltip": {
        "shared": false,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "datasource": null,
      "description": "The Consumption of allocated RAM",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 8,
        "x": 0,
        "y": 9
      },
      "id": 2,
      "options": {
        "displayMode": "gradient",
        "orientation": "vertical",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        },
        "showUnfilled": true
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "100 * (1 - sum(collectd_memory{memory=\"free\"}) by (exported_instance) / sum(collectd_memory) by (exported_instance))",
          "instant": false,
          "interval": "",
          "legendFormat": "{{exported_instance}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Memory Consumption",
      "transparent": true,
      "type": "bargauge"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": null,
      "description": "The data regards every machine main disk (sda) I/O Total Time",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 5,
      "gridPos": {
        "h": 8,
        "w": 16,
        "x": 8,
        "y": 9
      },
      "hiddenSeries": false,
      "id": 10,
      "legend": {
        "alignAsTable": false,
        "avg": true,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": false,
        "min": false,
        "rightSide": false,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null as zero",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(collectd_disk_disk_io_time_io_time_total[30s])",
          "interval": "",
          "legendFormat": "{{exported_instance}}:{{disk}}",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Disk I/O Operation Time",
      "tooltip": {
        "shared": true,
        "sort": 2,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "datasource": "Loki",
      "description": "Aggregation of Logs from different Hosts.",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 17
      },
      "id": 6,
      "options": {
        "showLabels": false,
        "showTime": true,
        "sortOrder": "Descending",
        "wrapLogMessage": true
      },
      "pluginVersion": "7.0.1",
      "targets": [
        {
          "expr": "{agent=\"promtail\"}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "OpenStack Controller Logs",
      "type": "logs"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 25,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-5m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "OpenStack",
  "uid": "oebZg-zMz",
  "version": 2
}
EOF



cat > /var/lib/grafana/dashboards/Clients.json << EOF
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "Information Regarding the Clients of this cloud",
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 3,
  "links": [],
  "panels": [
    {
      "datasource": null,
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 11,
        "w": 11,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "irate(collectd_virt_virt_vcpu_total[5m]) / 10000000",
          "interval": "",
          "legendFormat": "{{virt}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Use of vCPU allocated  for Guests",
      "type": "stat"
    },
    {
      "datasource": null,
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "decgbytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 11,
        "w": 12,
        "x": 11,
        "y": 0
      },
      "id": 6,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "collectd_virt_memory{type=\"unused\"}/1073741824",
          "instant": false,
          "interval": "",
          "legendFormat": "{{virt}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Guest Unused Memory",
      "type": "stat"
    },
    {
      "datasource": "Loki",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "gridPos": {
        "h": 10,
        "w": 23,
        "x": 0,
        "y": 11
      },
      "id": 8,
      "options": {
        "showLabels": true,
        "showTime": true,
        "sortOrder": "Descending",
        "wrapLogMessage": true
      },
      "targets": [
        {
          "expr": "{job=\"varlogs\"}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "General Logs",
      "type": "logs"
    }
  ],
  "refresh": false,
  "schemaVersion": 25,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now/y",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "Clients",
  "uid": "fXzUSviGk",
  "version": 5
}
EOF


sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo 'Grafana Started on port 3000, access it to to configure your credentials'

touch /.grafana.stamp

























