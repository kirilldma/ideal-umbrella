FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    locales \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    systemd systemd-sysv \
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
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd

RUN cat > /etc/profile.d/arnautsky.sh << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
alias ll='ls -la'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'
EOF

RUN cat > /etc/motd << 'EOF'

  █████╗ ██████╗ ███╗   ██╗ █████╗ ██╗   ██╗████████╗███████╗██╗  ██╗██╗   ██╗
 ██╔══██╗██╔══██╗████╗  ██║██╔══██╗██║   ██║╚══██╔══╝██╔════╝██║ ██╔╝╚██╗ ██╔╝
 ███████║██████╔╝██╔██╗ ██║███████║██║   ██║   ██║   ███████╗█████╔╝  ╚████╔╝ 
 ██╔══██║██╔══██╗██║╚██╗██║██╔══██║██║   ██║   ██║   ╚════██║██╔═██╗   ╚██╔╝  
 ██║  ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝   ██║   ███████║██║  ██╗   ██║   
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝  
                                                          arnautsky.mom
EOF

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

STOPSIGNAL SIGRTMIN+3
CMD ["/entrypoint.sh"]

RUN echo '#!/bin/bash\nkill -SIGRTMIN+3 1' > /usr/local/bin/reboot && \
    chmod +x /usr/local/bin/reboot && \
    echo '#!/bin/bash\nkill -SIGRTMIN+3 1' > /usr/local/bin/shutdown && \
    chmod +x /usr/local/bin/shutdown
