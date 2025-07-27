#!/bin/sh

# Configure SSH authentication
if [ -n "$ROOT_PASSWORD" ]; then
    # Enable password authentication if password is provided
    echo "root:$ROOT_PASSWORD" | chpasswd
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
    # Disable password authentication if no password is set
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Configure SSH public key if provided
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /root/.ssh
    echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh
    chown root:root /root/.ssh/authorized_keys
fi

# Configure SSH port
SSH_PORT=${SSH_PORT:-22}
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

# Enable IP forwarding for exit node functionality if enabled
if [ "$EXIT_NODE" = "true" ]; then
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    sysctl -p
fi

# Start Tailscale daemon with userspace networking (no TUN device required)
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --tun=userspace-networking &

# Authenticate with Tailscale if auth key provided
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    sleep 2
    # Configure as exit node if enabled
    if [ "$EXIT_NODE" = "true" ]; then
        echo "Configuring as exit node..."
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-docker-host}" --advertise-exit-node --accept-routes --accept-dns=false --timeout=0s --advertise-tags=tag:exit
        echo "Exit node configuration complete"
    else
        echo "Configuring as regular node..."
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-docker-host}" --accept-routes --accept-dns=false --timeout=0s
        echo "Regular node configuration complete"
    fi
fi

# Start Cloudflared tunnel if token provided
if [ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
    cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN" &
fi

# Start SSH daemon
exec /usr/sbin/sshd -D -p "$SSH_PORT"
