FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    container=docker

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    curl wget \
    btop htop \
    net-tools iproute2 iputils-ping \
    vim nano \
    git \
    sudo \
    procps \
    ca-certificates \
    unzip zip tar \
    python3 python3-pip \
    iptables \
    fuse-overlayfs \
    kmod \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Docker CE
RUN curl -fsSL https://get.docker.com | sh

# cloudflared
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

# SSH
RUN echo 'root:arnautsky' | chpasswd \
    && mkdir -p /run/sshd \
    && sed -i \
        -e 's/#PermitRootLogin.*/PermitRootLogin yes/' \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication yes/' \
        -e 's/PasswordAuthentication no/PasswordAuthentication yes/' \
        -e 's/#Port 22/Port 22/' \
        /etc/ssh/sshd_config

# Docker rootless fallback config
RUN mkdir -p /etc/docker && cat > /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "fuse-overlayfs",
  "iptables": false,
  "bridge": "none",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

RUN cat > /etc/profile.d/arnautsky.sh << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
alias ll='ls -la'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'
alias dps='docker ps'
alias dlog='docker logs -f'
EOF

RUN cat > /etc/motd << 'EOF'
  █████╗ ██████╗ ███╗   ██╗ █████╗ ██╗   ██╗████████╗███████╗██╗  ██╗██╗   ██╗
 ██╔══██╗██╔══██╗████╗  ██║██╔══██╗██║   ██║╚══██╔══╝██╔════╝██║ ██╔╝╚██╗ ██╔╝
 ███████║██████╔╝██╔██╗ ██║███████║██║   ██║   ██║   ███████╗█████╔╝  ╚████╔╝ 
 ██╔══██║██╔══██╗██║╚██╗██║██╔══██║██║   ██║   ██║   ╚════██║██╔═██╗   ╚██╔╝  
 ██║  ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝   ██║   ███████║██║  ██╗   ██║   
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝  
                                                           arnautsky.mom
  Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
  IP:     $(curl -s ifconfig.me 2>/dev/null)
EOF

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

STOPSIGNAL SIGTERM
CMD ["/entrypoint.sh"]
