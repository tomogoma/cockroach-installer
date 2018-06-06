#!/bin/bash

INSTALL_DIR="/usr/local/bin"
BIN_PATH="$INSTALL_DIR/cockroach"
SYSTEMD_FILE="/etc/systemd/system/cockroach.*.service"

echo "Uninstalling..."

if [ -f "$SYSTEMD_FILE" ]; then
	systemctl stop cockroach.*.service >/dev/null
	rm -f "$SYSTEMD_FILE"
    systemctl daemon-reload
fi

if [ -f "$BIN_PATH" ]; then
	rm -f "$BIN_PATH"
fi

if [ -f "/usr/local/bin/cconnect" ]; then
    rm "/usr/local/bin/cconnect"
fi

echo "Data and cert dirs have been left intact"
echo "Done!"

exit 0
