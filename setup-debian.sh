#!/bin/sh

echo_info() {
    GREEN='\033[0;32m'
    NC='\033[0m'
    printf "${GREEN}$1${NC}\n"
}

###############################################################################
# Update system
###############################################################################

# update & upgrade
echo_info "Updating system..."
apt update && apt upgrade --yes

###############################################################################
# Enable automatic updates
###############################################################################

echo_info "Enabling automatic updates..."
apt install --yes --no-install-recommends unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades

###############################################################################
# Install software
###############################################################################

# install basic software
echo_info "Installing basic software..."
apt install --yes --no-install-recommends gnupg git

# install bridge-utils
echo_info "Installing bridge-utils..."
apt install --yes --no-install-recommends bridge-utils

# install and setup ssh server
echo_info "Installing SSH server..."
apt install --yes --no-install-recommends openssh-server

# install wireguard
echo_info "Installing wireguard..."
# install kernel headers
apt install --yes --no-install-recommends linux-headers-amd64
apt install --yes --no-install-recommends wireguard

# install docker
# https://github.com/docker/docker-install
echo_info "Installing docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

###############################################################################
# Required system configuration
###############################################################################

# change ssh port
echo_info "Changing SSH port to 2222"
if ! grep -Fxq "Port 2222"    /etc/ssh/sshd_config ; then
    echo       "Port 2222" >> /etc/ssh/sshd_config
    systemctl restart ssh
fi

# enable ipv4 forwarding
echo_info "Enabling IPv4 Forwarding"
if ! grep -Fxq "net.ipv4.ip_forward=1"    /etc/sysctl.conf ; then
    echo       "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    sysctl -p
fi

# enable ipv6 forwarding
echo_info "Enabling IPv6 Forwarding"
if ! grep -Fxq "net.ipv6.conf.all.forwarding=1"    /etc/sysctl.conf ; then
    echo       "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

    sysctl -p
fi

###############################################################################
# System optimization (optional)
###############################################################################

# enable bbr congestion control
echo_info "Enabling BBR Congestion Control"
if ! grep -Fxq "net.ipv4.tcp_congestion_control=bbr"    /etc/sysctl.conf ; then
    echo       "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    sysctl -p
fi
if ! grep -Fxq "net.core.default_qdisc=fq"    /etc/sysctl.conf ; then
    echo       "net.core.default_qdisc=fq" >> /etc/sysctl.conf

    sysctl -p
fi

# set max UDP buffer for QUIC
if ! grep -Fxq "net.core.rmem_max=2500000"    /etc/sysctl.conf ; then
    echo       "net.core.rmem_max=2500000" >> /etc/sysctl.conf

    sysctl -p
fi

###############################################################################
# Install resolvconf at last (May break DNS)
###############################################################################

# install resolvconf
echo_info "Installing resolvconf"
apt install --yes --no-install-recommends resolvconf

###############################################################################
###############################################################################
###############################################################################
# Finish, reboot
echo_info "Finish, rebooting..."
reboot
