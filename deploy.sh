#!/bin/sh

echo_info() {
    GREEN='\033[0;32m'
    NC='\033[0m'
    printf "${GREEN}$1${NC}\n"
}

# Update repository & submodules
echo_info "Updating repositories..."

git pull
git submodule update --init --recursive
git submodule update --recursive --remote

# Reveal secrets
# echo_info "Revealing secrets..."
# git secret reveal -f

# Update and start containers
echo_info "Updating docker images..."
docker-compose pull

echo_info "Set up docker containers..."
docker-compose up -d --build --force-recreate --remove-orphans
