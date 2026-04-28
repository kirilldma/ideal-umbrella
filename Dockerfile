FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    systemd systemd-sysv \
    openssh-server \
    curl wget \
    locales \
    btop htop \
    net-tools iproute2 iputils-ping \
    vim nano \
    git \
    sudo \
    procps \
    ca-certificates \
    unzip zip \
    tar \
    python3 python3-pip \
    nodejs npm \
    ufw \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared trixie main" > /etc/apt/sources.list.d/cloudflared.list && \
    apt-get update && apt-get install -y cloudflared && \
    rm -rf /var/lib/apt/lists/*

RUN cat > /etc/motd << 'EOF'
    ___                           __       __        
   /   |  _________  ____ ___  __/ /______/ /____  __
  / /| | / ___/ __ \/ __ `/ / / / __/ ___/ //_/ / / /
 / ___ |/ /  / / / / /_/ / /_/ / /_(__  ) ,< / /_/ / 
/_/  |_/_/  /_/ /_/\__,_/\__,_/\__/____/_/|_|\__, /  
                                            /____/      

   Arnautsky.mom VPS | BETA
EOF

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

STOPSIGNAL SIGRTMIN+3
CMD ["/entrypoint.sh"]
