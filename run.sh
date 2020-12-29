#!/bin/bash

PUBLIC_IP_ADDRESS=$(curl eth0.me)

echo "Configure Docker."

firewall-cmd --zone=public --add-port=9323/tcp


cat <<EOF > /etc/docker/daemon.json
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
EOF

systemctl restart docker

echo "Update prometheus.yml."

cat <<EOF > ~/prometheus.yml
scrape_configs:
  - job_name: prometheus
    scrape_interval: 5s
    static_configs:
    - targets:
      - prometheus:9090
      - node-exporter:9100
      - pushgateway:9091
      - cadvisor:8080

  - job_name: docker
    scrape_interval: 5s
    static_configs:
    - targets:
      - <PRIVATE_IP_ADDRESS>:9323
EOF

echo "Update docker-compose.yml."

cat <<EOF > ~/docker-compose.yml
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - 9090:9090
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    depends_on:
      - cadvisor
  cadvisor:
    image: google/cadvisor:latest
    container_name: cadvisor
    ports:
      - 8080:8080
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
  pushgateway:
    image: prom/pushgateway
    container_name: pushgateway
    ports:
      - 9091:9091
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    expose:
      - 9100
  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - 3000:3000
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=password
    depends_on:
      - prometheus
      - cadvisor
EOF

docker-compose up -d

echo "Install the Docker and System Monitoring dashboard."
#Click the plus sign (+) on the left side of the Grafana interface. Click Import. Copy the contents of the JSON file included in the lab instructions.

#Paste the contents of the JSON file into the Import screen of the Grafana interface, and click Load. In the upper right-hand corner, click on Refresh every 5m and select Last 5 minutes.

echo "http://$PUBLIC_IP_ADDRESS:9090"

echo "http://$PUBLIC_IP_ADDRESS:3000"

cat <<EOF > ~/docker_and_system.json
{
"__inputs": [
{
"name": "DS_PROMETHEUS",
"label": "Prometheus",
"description": "",
"type": "datasource",
"pluginId": "prometheus",
"pluginName": "Prometheus"
}
],
"__requires": [
{
"type": "grafana",
"id": "grafana",
"name": "Grafana",
"version": "5.2.3"
},
{
"type": "panel",
"id": "graph",
"name": "Graph",
"version": "5.0.0"
},
{
"type": "datasource",
"id": "prometheus",
"name": "Prometheus",
"version": "5.0.0"
},
{
"type": "panel",
"id": "singlestat",
"name": "Singlestat",
"version": "5.0.0"
},
{
"type": "panel",
"id": "table",
"name": "Table",
"version": "5.0.0"
}
],
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
"description": "A simple overview of the most important Docker host and container metrics. (cAdvisor/Prometheus)",
"editable": true,
"gnetId": 893,
"graphTooltip": 1,
"id": null,
"iteration": 1535656991954,
"links": [],
"panels": [
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(245, 54, 54, 0.9)",
"rgba(237, 129, 40, 0.89)",
"rgba(50, 172, 45, 0.97)"
],
"datasource": "${DS_PROMETHEUS}",
"decimals": 0,
"editable": true,
"error": false,
"format": "s",
"gauge": {
"maxValue": 100,
"minValue": 0,
"show": false,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 0,
"y": 0
},
"height": "",
"id": 24,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "30%",
"prefix": "",
"prefixFontSize": "20%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(31, 118, 189, 0.18)",
"full": false,
"lineColor": "rgb(31, 120, 193)",
"show": false
},
"tableColumn": "",
"targets": [
{
"expr": "time() - node_boot_time_seconds{instance=~\".*\"}",
"format": "time_series",
"hide": false,
"intervalFactor": 2,
"legendFormat": "",
"refId": "A",
"step": 1800
}
],
"thresholds": "",
"title": "Uptime",
"type": "singlestat",
"valueFontSize": "80%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "current"
},
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(245, 54, 54, 0.9)",
"rgba(237, 129, 40, 0.89)",
"rgba(50, 172, 45, 0.97)"
],
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"format": "none",
"gauge": {
"maxValue": 100,
"minValue": 0,
"show": false,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 4,
"y": 0
},
"id": 31,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "50%",
"prefix": "",
"prefixFontSize": "50%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(31, 118, 189, 0.18)",
"full": false,
"lineColor": "rgb(31, 120, 193)",
"show": false
},
"tableColumn": "",
"targets": [
{
"expr": "count(rate(container_last_seen{name=~\".+\"}[$interval]))",
"intervalFactor": 2,
"refId": "A",
"step": 1800
}
],
"thresholds": "",
"title": "Containers",
"type": "singlestat",
"valueFontSize": "120%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "current"
},
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(50, 172, 45, 0.97)",
"rgba(237, 129, 40, 0.89)",
"rgba(245, 54, 54, 0.9)"
],
"datasource": "${DS_PROMETHEUS}",
"decimals": 1,
"editable": true,
"error": false,
"format": "percentunit",
"gauge": {
"maxValue": 1,
"minValue": 0,
"show": true,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 8,
"y": 0
},
"id": 26,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "50%",
"prefix": "",
"prefixFontSize": "50%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(31, 118, 189, 0.18)",
"full": false,
"lineColor": "rgb(31, 120, 193)",
"show": false
},
"tableColumn": "",
"targets": [
{
"expr": "min((node_filesystem_size_bytes{fstype=~\"xfs|ext4\",instance=~\".+\"} - node_filesystem_free_bytes{fstype=~\"xfs|ext4\",instance=~\".+\"} )/ node_filesystem_size_bytes{fstype=~\"xfs|ext4\",instance=~\".+\"})",
"format": "time_series",
"hide": false,
"intervalFactor": 2,
"refId": "A",
"step": 1800
}
],
"thresholds": "0.75, 0.90",
"title": "Disk space",
"type": "singlestat",
"valueFontSize": "80%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "current"
},
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(50, 172, 45, 0.97)",
"rgba(237, 129, 40, 0.89)",
"rgba(245, 54, 54, 0.9)"
],
"datasource": "${DS_PROMETHEUS}",
"decimals": 0,
"editable": true,
"error": false,
"format": "percent",
"gauge": {
"maxValue": 100,
"minValue": 0,
"show": true,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 12,
"y": 0
},
"id": 25,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "50%",
"prefix": "",
"prefixFontSize": "50%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(31, 118, 189, 0.18)",
"full": false,
"lineColor": "rgb(31, 120, 193)",
"show": false
},
"tableColumn": "",
"targets": [
{
"expr": "((node_memory_MemTotal_bytes{instance=~\".+\"} - node_memory_MemAvailable_bytes{instance=~\".+\"}) / node_memory_MemTotal_bytes{instance=~\".+\"}) * 100",
"format": "time_series",
"intervalFactor": 2,
"refId": "A",
"step": 1800
}
],
"thresholds": "70, 90",
"title": "Memory",
"type": "singlestat",
"valueFontSize": "80%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "current"
},
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(50, 172, 45, 0.97)",
"rgba(237, 129, 40, 0.89)",
"rgba(245, 54, 54, 0.9)"
],
"datasource": "${DS_PROMETHEUS}",
"decimals": 0,
"editable": true,
"error": false,
"format": "decbytes",
"gauge": {
"maxValue": 500000000,
"minValue": 0,
"show": true,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 16,
"y": 0
},
"id": 30,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "50%",
"prefix": "",
"prefixFontSize": "50%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(31, 118, 189, 0.18)",
"full": false,
"lineColor": "rgb(31, 120, 193)",
"show": false
},
"tableColumn": "",
"targets": [
{
"expr": "(node_memory_SwapTotal_bytes{instance=~'.*'} - node_memory_SwapFree_bytes{instance=~'.*'})",
"format": "time_series",
"intervalFactor": 2,
"legendFormat": "",
"refId": "A",
"step": 1800
}
],
"thresholds": "400000000",
"title": "Swap",
"type": "singlestat",
"valueFontSize": "80%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "current"
},
{
"cacheTimeout": null,
"colorBackground": false,
"colorValue": false,
"colors": [
"rgba(245, 54, 54, 0.9)",
"rgba(237, 129, 40, 0.89)",
"rgba(50, 172, 45, 0.97)"
],
"datasource": "${DS_PROMETHEUS}",
"decimals": 0,
"editable": true,
"error": false,
"format": "percentunit",
"gauge": {
"maxValue": 100,
"minValue": 0,
"show": false,
"thresholdLabels": false,
"thresholdMarkers": true
},
"gridPos": {
"h": 4,
"w": 4,
"x": 20,
"y": 0
},
"id": 27,
"interval": null,
"links": [],
"mappingType": 1,
"mappingTypes": [
{
"name": "value to text",
"value": 1
},
{
"name": "range to text",
"value": 2
}
],
"maxDataPoints": 100,
"nullPointMode": "connected",
"nullText": null,
"postfix": "",
"postfixFontSize": "50%",
"prefix": "",
"prefixFontSize": "50%",
"rangeMaps": [
{
"from": "null",
"text": "N/A",
"to": "null"
}
],
"sparkline": {
"fillColor": "rgba(50, 189, 31, 0.18)",
"full": false,
"lineColor": "rgb(69, 193, 31)",
"show": true
},
"tableColumn": "",
"targets": [
{
"expr": "node_load1{instance=~\".*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu_seconds_total{instance=~\".*\"}))",
"format": "time_series",
"intervalFactor": 2,
"refId": "A",
"step": 1800
}
],
"thresholds": "0.8,0.9",
"title": "Load",
"type": "singlestat",
"valueFontSize": "80%",
"valueMaps": [
{
"op": "=",
"text": "N/A",
"value": "null"
}
],
"valueName": "avg"
},
{
"aliasColors": {
"SENT": "#BF1B00"
},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 6,
"w": 4,
"x": 0,
"y": 4
},
"id": 19,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 1,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": false,
"steppedLine": false,
"targets": [
{
"expr": "sum(rate(container_network_receive_bytes_total{id=\"/\"}[$interval])) by (id)",
"intervalFactor": 2,
"legendFormat": "RECEIVED",
"refId": "A",
"step": 600
},
{
"expr": "- sum(rate(container_network_transmit_bytes_total{id=\"/\"}[$interval])) by (id)",
"hide": false,
"intervalFactor": 2,
"legendFormat": "SENT",
"refId": "B",
"step": 600
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Network Traffic",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "cumulative"
},
"transparent": false,
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "bytes",
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
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"aliasColors": {
"{id=\"/\",instance=\"cadvisor:8080\",job=\"prometheus\"}": "#BA43A9"
},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 6,
"w": 4,
"x": 4,
"y": 4
},
"id": 5,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "sum(rate(container_cpu_system_seconds_total[1m]))",
"hide": true,
"intervalFactor": 2,
"legendFormat": "a",
"refId": "B",
"step": 120
},
{
"expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m]))",
"hide": true,
"interval": "",
"intervalFactor": 2,
"legendFormat": "nur container",
"refId": "F",
"step": 10
},
{
"expr": "sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m]))",
"hide": true,
"interval": "",
"intervalFactor": 2,
"legendFormat": "nur docker host",
"metric": "",
"refId": "A",
"step": 20
},
{
"expr": "sum(rate(process_cpu_seconds_total[$interval])) * 100",
"hide": false,
"interval": "",
"intervalFactor": 2,
"legendFormat": "host",
"metric": "",
"refId": "C",
"step": 600
},
{
"expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m])) + sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m])) + sum(rate(process_cpu_seconds_total[1m]))",
"hide": true,
"intervalFactor": 2,
"legendFormat": "",
"refId": "D",
"step": 120
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "CPU Usage",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "cumulative"
},
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "percent",
"label": "",
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
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"alert": {
"conditions": [
{
"evaluator": {
"params": [
1.25
],
"type": "gt"
},
"query": {
"params": [
"A",
"5m",
"now"
]
},
"reducer": {
"params": [],
"type": "avg"
},
"type": "query"
}
],
"executionErrorState": "alerting",
"frequency": "60s",
"handler": 1,
"name": "Panel Title alert",
"noDataState": "keep_state",
"notifications": [
{
"id": 1
}
]
},
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"decimals": 0,
"editable": true,
"error": false,
"fill": 1,
"gridPos": {
"h": 6,
"w": 4,
"x": 8,
"y": 4
},
"id": 28,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "connected",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": false,
"steppedLine": false,
"targets": [
{
"expr": "node_load1{instance=~\".*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu_seconds_total{instance=~\".*\"}))",
"format": "time_series",
"intervalFactor": 2,
"refId": "A",
"step": 600
}
],
"thresholds": [
{
"colorMode": "critical",
"fill": true,
"line": true,
"op": "gt",
"value": 1.25
}
],
"timeFrom": null,
"timeShift": null,
"title": "Load",
"tooltip": {
"msResolution": false,
"shared": true,
"sort": 0,
"value_type": "individual"
},
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "percentunit",
"label": null,
"logBase": 1,
"max": "1.50",
"min": null,
"show": true
},
{
"format": "short",
"label": null,
"logBase": 1,
"max": null,
"min": null,
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"alert": {
"conditions": [
{
"evaluator": {
"params": [
850000000000
],
"type": "gt"
},
"query": {
"params": [
"A",
"5m",
"now"
]
},
"reducer": {
"params": [],
"type": "avg"
},
"type": "query"
}
],
"executionErrorState": "alerting",
"frequency": "60s",
"handler": 1,
"name": "Free/Used Disk Space alert",
"noDataState": "keep_state",
"notifications": [
{
"id": 1
}
]
},
"aliasColors": {
"Belegete Festplatte": "#BF1B00",
"Free Disk Space": "#7EB26D",
"Used Disk Space": "#7EB26D",
"{}": "#BF1B00"
},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 6,
"w": 4,
"x": 12,
"y": 4
},
"id": 13,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [
{
"alias": "Used Disk Space",
"yaxis": 1
}
],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "node_filesystem_size_bytes{fstype=\"xfs\"} - node_filesystem_free_bytes{fstype=\"xfs\"}",
"format": "time_series",
"hide": false,
"intervalFactor": 2,
"legendFormat": "Used Disk Space",
"refId": "A",
"step": 600
}
],
"thresholds": [
{
"colorMode": "critical",
"fill": true,
"line": true,
"op": "gt",
"value": 850000000000
}
],
"timeFrom": null,
"timeShift": null,
"title": "Used Disk Space",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "individual"
},
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "bytes",
"label": "",
"logBase": 1,
"max": 1000000000000,
"min": 0,
"show": true
},
{
"format": "short",
"label": null,
"logBase": 1,
"max": null,
"min": null,
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"alert": {
"conditions": [
{
"evaluator": {
"params": [
10000000000
],
"type": "gt"
},
"query": {
"params": [
"A",
"5m",
"now"
]
},
"reducer": {
"params": [],
"type": "avg"
},
"type": "query"
}
],
"executionErrorState": "alerting",
"frequency": "60s",
"handler": 1,
"name": "Available Memory alert",
"noDataState": "keep_state",
"notifications": [
{
"id": 1
}
]
},
"aliasColors": {
"Available Memory": "#7EB26D",
"Unavailable Memory": "#7EB26D"
},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 6,
"w": 4,
"x": 16,
"y": 4
},
"id": 20,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "container_memory_rss{name=~\".+\"}",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "D",
"step": 20
},
{
"expr": "sum(container_memory_rss{name=~\".+\"})",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "A",
"step": 20
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 20
},
{
"expr": "container_memory_rss{id=\"/\"}",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "C",
"step": 20
},
{
"expr": "sum(container_memory_rss)",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "E",
"step": 20
},
{
"expr": "node_memory_Buffers",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "node_memory_Dirty",
"refId": "N",
"step": 30
},
{
"expr": "node_memory_MemFree",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "F",
"step": 20
},
{
"expr": "node_memory_MemAvailable",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "Available Memory",
"refId": "H",
"step": 20
},
{
"expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes",
"format": "time_series",
"hide": false,
"intervalFactor": 2,
"legendFormat": "Unavailable Memory",
"refId": "G",
"step": 600
},
{
"expr": "node_memory_Inactive",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "I",
"step": 30
},
{
"expr": "node_memory_KernelStack",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "J",
"step": 30
},
{
"expr": "node_memory_Active",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "K",
"step": 30
},
{
"expr": "node_memory_MemTotal - (node_memory_Active + node_memory_MemFree + node_memory_Inactive)",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "Unknown",
"refId": "L",
"step": 40
},
{
"expr": "node_memory_MemFree + node_memory_Inactive ",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "M",
"step": 30
},
{
"expr": "container_memory_rss{name=~\".+\"}",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{__name__}}",
"refId": "O",
"step": 30
},
{
"expr": "node_memory_Inactive + node_memory_MemFree + node_memory_MemAvailable",
"format": "time_series",
"hide": true,
"intervalFactor": 2,
"legendFormat": "",
"refId": "P",
"step": 40
}
],
"thresholds": [
{
"colorMode": "critical",
"fill": true,
"line": true,
"op": "gt",
"value": 10000000000
}
],
"timeFrom": null,
"timeShift": null,
"title": "Available Memory",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "individual"
},
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "bytes",
"label": "",
"logBase": 1,
"max": 16000000000,
"min": 0,
"show": true
},
{
"format": "short",
"label": null,
"logBase": 1,
"max": null,
"min": null,
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"aliasColors": {
"IN on /sda": "#7EB26D",
"OUT on /sda": "#890F02"
},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 6,
"w": 4,
"x": 20,
"y": 4
},
"id": 3,
"legend": {
"avg": false,
"current": false,
"max": false,
"min": false,
"show": false,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": false,
"steppedLine": false,
"targets": [
{
"expr": "-sum(rate(node_disk_read_bytes_total[$interval])) by (device)",
"format": "time_series",
"hide": false,
"intervalFactor": 2,
"legendFormat": "OUT on /{{device}}",
"metric": "node_disk_bytes_read",
"refId": "A",
"step": 600
},
{
"expr": "sum(rate(node_disk_written_bytes_total[$interval])) by (device)",
"format": "time_series",
"intervalFactor": 2,
"legendFormat": "IN on /{{device}}",
"metric": "",
"refId": "B",
"step": 600
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Disk I/O",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "cumulative"
},
"type": "graph",
"xaxis": {
"buckets": null,
"mode": "time",
"name": null,
"show": false,
"values": []
},
"yaxes": [
{
"format": "Bps",
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
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 7,
"w": 12,
"x": 0,
"y": 10
},
"id": 8,
"legend": {
"alignAsTable": true,
"avg": false,
"current": false,
"max": false,
"min": false,
"rightSide": true,
"show": true,
"total": false,
"values": false
},
"lines": true,
"linewidth": 2,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": false,
"steppedLine": false,
"targets": [
{
"expr": "sum(rate(container_network_receive_bytes_total{name=~\".+\"}[$interval])) by (name)",
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "A",
"step": 240
},
{
"expr": "- rate(container_network_transmit_bytes_total{name=~\".+\"}[$interval])",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 10
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Received Network Traffic per Container",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "cumulative"
},
"transparent": false,
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
"format": "Bps",
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
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 1,
"grid": {},
"gridPos": {
"h": 7,
"w": 12,
"x": 12,
"y": 10
},
"id": 9,
"legend": {
"alignAsTable": true,
"avg": false,
"current": false,
"hideEmpty": false,
"hideZero": false,
"max": false,
"min": false,
"rightSide": true,
"show": true,
"total": false,
"values": false
},
"lines": true,
"linewidth": 2,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": false,
"steppedLine": false,
"targets": [
{
"expr": "sum(rate(container_network_transmit_bytes_total{name=~\".+\"}[$interval])) by (name)",
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "A",
"step": 240
},
{
"expr": "rate(container_network_transmit_bytes_total{id=\"/\"}[$interval])",
"hide": true,
"intervalFactor": 2,
"legendFormat": "",
"refId": "B",
"step": 10
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Sent Network Traffic per Container",
"tooltip": {
"msResolution": true,
"shared": true,
"sort": 0,
"value_type": "cumulative"
},
"transparent": false,
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
"format": "Bps",
"label": "",
"logBase": 1,
"max": null,
"min": null,
"show": true
},
{
"format": "short",
"label": "",
"logBase": 10,
"max": 8,
"min": 0,
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 5,
"grid": {},
"gridPos": {
"h": 7,
"w": 12,
"x": 0,
"y": 17
},
"id": 1,
"legend": {
"alignAsTable": true,
"avg": false,
"current": false,
"max": false,
"min": false,
"rightSide": true,
"show": true,
"total": false,
"values": false
},
"lines": true,
"linewidth": 1,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".+\"}[$interval])) by (name) * 100",
"hide": false,
"interval": "",
"intervalFactor": 2,
"legendFormat": "{{name}}",
"metric": "",
"refId": "F",
"step": 240
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "CPU Usage per Container",
"tooltip": {
"msResolution": true,
"shared": true,
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
"format": "percent",
"label": "",
"logBase": 1,
"max": null,
"show": true
},
{
"format": "short",
"label": null,
"logBase": 1,
"max": null,
"min": null,
"show": false
}
],
"yaxis": {
"align": false,
"alignLevel": null
}
},
{
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 3,
"grid": {},
"gridPos": {
"h": 7,
"w": 12,
"x": 12,
"y": 17
},
"id": 34,
"legend": {
"alignAsTable": true,
"avg": false,
"current": false,
"max": false,
"min": false,
"rightSide": true,
"show": true,
"total": false,
"values": false
},
"lines": true,
"linewidth": 2,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "sum(container_memory_swap{name=~\".+\"}) by (name)",
"hide": false,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "A",
"step": 240
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 240
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Memory Swap per Container",
"tooltip": {
"msResolution": true,
"shared": true,
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
"format": "bytes",
"label": "",
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
"aliasColors": {},
"bars": false,
"dashLength": 10,
"dashes": false,
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fill": 3,
"grid": {},
"gridPos": {
"h": 7,
"w": 12,
"x": 0,
"y": 24
},
"id": 10,
"legend": {
"alignAsTable": true,
"avg": false,
"current": false,
"max": false,
"min": false,
"rightSide": true,
"show": true,
"total": false,
"values": false
},
"lines": true,
"linewidth": 2,
"links": [],
"nullPointMode": "null as zero",
"percentage": false,
"pointradius": 5,
"points": false,
"renderer": "flot",
"seriesOverrides": [],
"spaceLength": 10,
"stack": true,
"steppedLine": false,
"targets": [
{
"expr": "sum(container_memory_rss{name=~\".+\"}) by (name)",
"hide": false,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "A",
"step": 240
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 240
}
],
"thresholds": [],
"timeFrom": null,
"timeShift": null,
"title": "Memory Usage per Container",
"tooltip": {
"msResolution": true,
"shared": true,
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
"format": "bytes",
"label": "",
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
"columns": [
{
"text": "Current",
"value": "current"
}
],
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fontSize": "100%",
"gridPos": {
"h": 10,
"w": 8,
"x": 16,
"y": 24
},
"id": 36,
"links": [],
"pageSize": null,
"scroll": true,
"showHeader": true,
"sort": {
"col": 0,
"desc": true
},
"styles": [
{
"colorMode": null,
"colors": [
"rgba(245, 54, 54, 0.9)",
"rgba(237, 129, 40, 0.89)",
"rgba(50, 172, 45, 0.97)"
],
"decimals": 2,
"pattern": "/.*/",
"thresholds": [
"10000000",
" 25000000"
],
"type": "number",
"unit": "decbytes"
}
],
"targets": [
{
"expr": "sum(container_spec_memory_limit_bytes{name=~\".+\"} - container_memory_usage_bytes{name=~\".+\"}) by (name) ",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"metric": "",
"refId": "A",
"step": 240
},
{
"expr": "sum(container_spec_memory_limit_bytes{name=~\".+\"}) by (name) ",
"hide": false,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 240
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "C",
"step": 240
}
],
"title": "Limit memory",
"transform": "timeseries_aggregations",
"type": "table"
},
{
"columns": [
{
"text": "Current",
"value": "current"
}
],
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fontSize": "100%",
"gridPos": {
"h": 10,
"w": 8,
"x": 0,
"y": 31
},
"id": 37,
"links": [],
"pageSize": null,
"scroll": true,
"showHeader": true,
"sort": {
"col": 0,
"desc": true
},
"styles": [
{
"colorMode": null,
"colors": [
"rgba(245, 54, 54, 0.9)",
"rgba(237, 129, 40, 0.89)",
"rgba(50, 172, 45, 0.97)"
],
"decimals": 2,
"pattern": "/.*/",
"thresholds": [
"10000000",
" 25000000"
],
"type": "number",
"unit": "decbytes"
}
],
"targets": [
{
"expr": "sum(container_spec_memory_limit_bytes{name=~\".+\"} - container_memory_usage_bytes{name=~\".+\"}) by (name) ",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"metric": "",
"refId": "A",
"step": 240
},
{
"expr": "sum(container_spec_memory_limit_bytes{name=~\".+\"}) by (name) ",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 240
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"hide": false,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "C",
"step": 240
}
],
"title": "Usage memory",
"transform": "timeseries_aggregations",
"type": "table"
},
{
"columns": [
{
"text": "Current",
"value": "current"
}
],
"datasource": "${DS_PROMETHEUS}",
"editable": true,
"error": false,
"fontSize": "100%",
"gridPos": {
"h": 10,
"w": 8,
"x": 8,
"y": 31
},
"id": 35,
"links": [],
"pageSize": null,
"scroll": true,
"showHeader": true,
"sort": {
"col": 1,
"desc": true
},
"styles": [
{
"colorMode": "cell",
"colors": [
"rgba(50, 172, 45, 0.97)",
"rgba(237, 129, 40, 0.89)",
"rgba(245, 54, 54, 0.9)"
],
"decimals": 2,
"pattern": "/.*/",
"thresholds": [
"80",
"90"
],
"type": "number",
"unit": "percent"
}
],
"targets": [
{
"expr": "sum(100 - ((container_spec_memory_limit_bytes{name=~\".+\"} - container_memory_usage_bytes{name=~\".+\"})  * 100 / container_spec_memory_limit_bytes{name=~\".+\"}) ) by (name) ",
"intervalFactor": 2,
"legendFormat": "{{name}}",
"metric": "",
"refId": "A",
"step": 240
},
{
"expr": "sum(container_spec_memory_limit_bytes{name=~\".+\"}) by (name) ",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "B",
"step": 240
},
{
"expr": "container_memory_usage_bytes{name=~\".+\"}",
"hide": true,
"intervalFactor": 2,
"legendFormat": "{{name}}",
"refId": "C",
"step": 240
}
],
"title": "Remaining memory",
"transform": "timeseries_aggregations",
"type": "table"
}
],
"refresh": "5m",
"schemaVersion": 16,
"style": "dark",
"tags": [],
"templating": {
"list": [
{
"allValue": ".+",
"current": {},
"datasource": "${DS_PROMETHEUS}",
"hide": 0,
"includeAll": true,
"label": "Container Group",
"multi": true,
"name": "containergroup",
"options": [],
"query": "label_values(container_group)",
"refresh": 1,
"regex": "",
"sort": 0,
"tagValuesQuery": null,
"tags": [],
"tagsQuery": null,
"type": "query",
"useTags": false
},
{
"auto": true,
"auto_count": 50,
"auto_min": "50s",
"current": {
"text": "auto",
"value": "$__auto_interval_interval"
},
"datasource": null,
"hide": 0,
"includeAll": false,
"label": "Interval",
"multi": false,
"name": "interval",
"options": [
{
"selected": true,
"text": "auto",
"value": "$__auto_interval_interval"
},
{
"selected": false,
"text": "30s",
"value": "30s"
},
{
"selected": false,
"text": "1m",
"value": "1m"
},
{
"selected": false,
"text": "2m",
"value": "2m"
},
{
"selected": false,
"text": "3m",
"value": "3m"
},
{
"selected": false,
"text": "5m",
"value": "5m"
},
{
"selected": false,
"text": "7m",
"value": "7m"
},
{
"selected": false,
"text": "10m",
"value": "10m"
},
{
"selected": false,
"text": "30m",
"value": "30m"
},
{
"selected": false,
"text": "1h",
"value": "1h"
},
{
"selected": false,
"text": "6h",
"value": "6h"
},
{
"selected": false,
"text": "12h",
"value": "12h"
},
{
"selected": false,
"text": "1d",
"value": "1d"
},
{
"selected": false,
"text": "7d",
"value": "7d"
},
{
"selected": false,
"text": "14d",
"value": "14d"
},
{
"selected": false,
"text": "30d",
"value": "30d"
}
],
"query": "30s,1m,2m,3m,5m,7m,10m,30m,1h,6h,12h,1d,7d,14d,30d",
"refresh": 2,
"type": "interval"
},
{
"allValue": null,
"current": {},
"datasource": "${DS_PROMETHEUS}",
"hide": 0,
"includeAll": false,
"label": "Node",
"multi": true,
"name": "server",
"options": [],
"query": "label_values(node_boot_time, instance)",
"refresh": 1,
"regex": "/([^:]+):.*/",
"sort": 0,
"tagValuesQuery": null,
"tags": [],
"tagsQuery": null,
"type": "query",
"useTags": false
}
]
},
"time": {
"from": "now-24h",
"to": "now"
},
"timepicker": {
"refresh_intervals": [
"5s",
"10s",
"30s",
"1m",
"5m",
"15m",
"30m",
"1h",
"2h",
"1d"
],
"time_options": [
"5m",
"15m",
"1h",
"6h",
"12h",
"24h",
"2d",
"7d",
"30d"
]
},
"timezone": "browser",
"title": "Docker and system monitoring",
"uid": "fTo9rH2ik",
"version": 12
}
EOF
