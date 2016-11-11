#!/bin/bash

APP_FILE="/usr/local/bin/cockroach"
ETCD_DIR="/etc/cockroachdb"
CERT_DIR="$ETCD_DIR/certs"
SYSTEMD_FILE="/etc/systemd/system/cockroach.service"
DATA_DIR="/var/data/cockroachdb/"

echo "Uninstalling..."

if [ -f "$APP_FILE" ]; then
	systemctl stop cockroach.service >/dev/null
	rm -rf "$APP_FILE"
fi

if [ -f "$SYSTEMD_FILE" ]; then
	rm -f "$SYSTEMD_FILE"
fi

if [ -d "$ETCD_DIR" ]; then
	rm -rf "$ETCD_DIR"
fi
if [ -f "/usr/local/bin/cconnect" ]; then
    rm "/usr/local/bin/cconnect"
fi
echo "Data at $DATA_DIR not removed, run 'rm $DATA_DIR' if you wish to delete"
echo "Done!"

`systemctl daemon-reload`

exit 0
