#!/bin/sh

echo_info() {
    GREEN='\033[0;32m'
    NC='\033[0m'
    printf "${GREEN}$1${NC}\n"
}

###############################################################################
# Update system
###############################################################################

# enable backports
echo_info "Enabling backports..."
. /etc/os-release
if ! apt search -t ${VERSION_CODENAME}-backports some_keywords >/dev/null 2>/dev/null ; then
    echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
        /etc/apt/sources.list.d/backports.list
    apt update
fi

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

# install git-secret
echo_info "Installing git-secret..."
wget -qO - 'https://gitsecret.jfrog.io/artifactory/api/gpg/key/public' | apt-key add -
echo 'deb https://gitsecret.jfrog.io/artifactory/git-secret-deb git-secret main' > /etc/apt/sources.list.d/git-secret.list
apt update
apt --yes --no-install-recommends install git-secret

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

# install cockpit
echo_info "Installing cockpit..."
. /etc/os-release
apt install --yes --no-install-recommends -t ${VERSION_CODENAME}-backports cockpit cockpit-pcp cockpit-doc cockpit-storaged cracklib-runtime

# install docker
# https://github.com/docker/docker-install
echo_info "Installing docker..."
apt remove --yes docker docker-engine docker.io containerd runc || true
apt --yes --no-install-recommends install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt --yes --no-install-recommends install docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker

# install docker compose
echo_info "Installing docker compose..."

wget --output-document=/usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/1.29.2/run.sh"
chmod +x /usr/local/bin/docker-compose
wget --output-document=/etc/bash_completion.d/docker-compose "https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose"

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
