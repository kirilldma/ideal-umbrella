#!/bin/bash
# entrypoint.sh

set -e

# Attempt privileged Docker daemon
start_docker() {
    if [ -e /dev/kvm ]; then
        echo "[*] KVM available"
    fi

    # Try native overlay first, fallback to fuse-overlayfs
    if docker info --format '{{.Driver}}' 2>/dev/null | grep -q overlay; then
        echo "[*] overlay2 ok"
    else
        echo "[*] falling back to fuse-overlayfs"
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'DOCKERCFG'
{
  "storage-driver": "fuse-overlayfs",
  "iptables": false
}
DOCKERCFG
    fi

    dockerd \
        --host=unix:///var/run/docker.sock \
        --storage-driver=overlay2 \
        2>/var/log/dockerd.log &

    DOCKER_PID=$!

    for i in $(seq 1 15); do
        docker info >/dev/null 2>&1 && break
        sleep 1
    done

    if ! docker info >/dev/null 2>&1; then
        echo "[!] overlay2 failed, retry with fuse-overlayfs"
        kill $DOCKER_PID 2>/dev/null || true
        cat > /etc/docker/daemon.json << 'DOCKERCFG'
{
  "storage-driver": "fuse-overlayfs",
  "iptables": false
}
DOCKERCFG
        dockerd \
            --host=unix:///var/run/docker.sock \
            2>/var/log/dockerd.log &

        sleep 5
    fi

    docker info >/dev/null 2>&1 \
        && echo "[*] Docker running" \
        || echo "[!] Docker unavailable (unprivileged container)"
}

# Cloudflare tunnel if token provided
start_cloudflared() {
    if [ -n "$CLOUDFLARE_TOKEN" ]; then
        cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TOKEN" &
        echo "[*] cloudflared started"
    elif [ -n "$CLOUDFLARE_URL" ]; then
        cloudflared tunnel --no-autoupdate --url "$CLOUDFLARE_URL" &
        echo "[*] cloudflared quick tunnel"
    fi
}

# Custom init scripts
run_init() {
    if [ -d /etc/init.d/custom ]; then
        for script in /etc/init.d/custom/*.sh; do
            [ -x "$script" ] && bash "$script" &
        done
    fi
}

echo "[*] Starting arnautsky environment"

start_docker
/usr/sbin/sshd -D &
start_cloudflared
run_init

echo "[*] SSH ready on :22"
echo "[*] root password: arnautsky"

wait
