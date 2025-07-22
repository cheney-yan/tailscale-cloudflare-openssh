FROM --platform=$BUILDPLATFORM alpine:3.19

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Install required packages
RUN apk add --no-cache \
    openssh-server \
    curl \
    ca-certificates \
    iptables \
    ip6tables

# Install Tailscale manually based on architecture
RUN case "$TARGETPLATFORM" in \
    "linux/amd64") ARCH="amd64" ;; \
    "linux/arm64") ARCH="arm64" ;; \
    *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    curl -fsSL "https://pkgs.tailscale.com/stable/tailscale_latest_${ARCH}.tgz" | tar xzf - --strip-components=1 -C /usr/local/bin/

# Install Cloudflared based on architecture
RUN case "$TARGETPLATFORM" in \
    "linux/amd64") ARCH="amd64" ;; \
    "linux/arm64") ARCH="arm64" ;; \
    *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    curl -L -o /usr/local/bin/cloudflared \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" && \
    chmod +x /usr/local/bin/cloudflared

# Configure SSH
RUN ssh-keygen -A && \
    mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
