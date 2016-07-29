#!/bin/bash

GRAFANA_HOST=${GRAFANA_HOST:-grafana}
GRAFANA_USER=admin
GRAFANA_PASS=changeme

echo -n "test grafana presence...   "
nslookup grafana >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo
  echo "failed"
  nslookup grafana
  exit 1
fi
printf "%-16s[OK]\n" "resolves"

echo -n "test grafana login page... "
i=0
r=1
while [[ $r -ne 0 ]]; do
  ((i++))
  sleep 1
  curl -L $GRAFANA_HOST:3000 2>/dev/null | grep -q '<title>Grafana</title>'
  r=$?
  if [[ $i -gt 40 ]]; then break; fi
done
if [[ $r -ne 0 ]]; then
  echo
  echo "failed"
  curl -L $GRAFANA_HOST:3000
  exit 1
fi
printf "%-16s[OK]\n" "ready (${i}s)"

echo -n "test grafana auth...       "
org=$(curl -u $GRAFANA_USER:$GRAFANA_PASS $GRAFANA_HOST:3000/api/org 2>/dev/null | jq -r '.name')
r=$?
if [[ $r -ne 0 || -z "$org" || "x$org" = "xnull" ]]; then
  echo
  echo "auth failed"
  curl -u $GRAFANA_USER:$GRAFANA_PASS $GRAFANA_HOST:3000/api/org 2>/dev/null
  exit 1
fi
printf "%-16s[OK]\n" "($org)"

echo -n "test grafana datasource... "
ds=$(curl -u $GRAFANA_USER:$GRAFANA_PASS $GRAFANA_HOST:3000/api/datasources/name/telegraf 2>/dev/null | jq -r '.name')
r=$?
if [[ $r -ne 0 || "x$ds" != "xtelegraf" ]]; then
  echo
  echo "failed to found datasource"
  exit 1
fi
printf "%-16s[OK]\n" "($ds)"

echo -n "test grafana dashboards... "
n=$(curl -u $GRAFANA_USER:$GRAFANA_PASS $GRAFANA_HOST:3000/api/search?query=AMP%20%Swarm%20Health 2>/dev/null | jq -r 'map(select(.type=="dash-db"))| length')
r=$?
if [[ $r -ne 0 || -z "$n" || "x$n" = "xnull" || $n -lt 1 ]]; then
  echo
  echo "failed to found dashboards"
  exit 1
fi
printf "%-16s[OK]\n" "($n)"
echo "all tests passed successfully"
