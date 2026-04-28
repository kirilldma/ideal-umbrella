#!/bin/bash

echo "================================"
echo " Arnautsky.mom VPS"
echo " SSH: root:root"
echo " Port: $SSH_PORT"
echo "================================"

mkdir -p /run/sshd

cat > /etc/profile.d/arnautsky.sh << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
alias ll='ls -la'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'
EOF

systemctl enable ssh 2>/dev/null || true

exec /usr/lib/systemd/systemd --system
