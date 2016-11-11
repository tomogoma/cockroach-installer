#!/bin/bash

APP_FILE="/usr/local/bin/cockroach"
ETCD_DIR="/etc/cockroachdb"
CERT_DIR="$ETCD_DIR/certs"
SYSTEMD_FILE="/etc/systemd/system/cockroach.service"
DATA_DIR="/var/data/cockroachdb/"

echo "Uninstalling..."

if [ -f "$SYSTEMD_FILE" ]; then
	systemctl stop cockroach.service >/dev/null
	rm -f "$SYSTEMD_FILE"
    systemctl daemon-reload
fi

if [ -f "$APP_FILE" ]; then
	rm -f "$APP_FILE"
fi

if [ -d "$ETCD_DIR" ]; then
	rm -rf "$ETCD_DIR"
fi
if [ -f "/usr/local/bin/cconnect" ]; then
    rm "/usr/local/bin/cconnect"
fi
echo "Data at $DATA_DIR not removed, run 'rm $DATA_DIR' if you wish to delete"
echo "Done!"

exit 0
