#!/bin/bash

echo "================================"
echo " Arnautsky.mom VPS"
echo " SSH: root:root"
echo "================================"

systemctl enable ssh 2>/dev/null || true

exec /usr/lib/systemd/systemd --system
