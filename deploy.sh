#!/bin/bash
# Deploy a Laravel site using the Docker LEMP stack.
#
# Usage:
#   First deployment:  ./deploy.sh
#   Subsequent deploys: ./deploy.sh update
#
# Prerequisites:
#   - Docker and Docker Compose installed
#   - Traefik stack running (see docker/traefik/)
#   - .env configured (copy from .env.sample)
#   - Laravel app in ./www/ with its own .env configured
#
# Required before first run:
#   1. cp .env.sample .env && edit .env
#   2. Clone/copy your Laravel app to ./www/
#   3. Configure www/.env (DB_HOST=mysql, REDIS_HOST=redis, etc.)
#   4. Generate SSL certs (see below)

set -euo pipefail

COMPOSE_CMD="docker compose -f docker-compose.yml -f docker-compose.prod.yml"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info() { echo "==> $*"; }
error() { echo "ERROR: $*" >&2; exit 1; }

check_prereqs() {
    [ -f .env ] || error ".env not found. Run: cp .env.sample .env"
    [ -d www ] || error "www/ directory not found. Clone your Laravel app there."
    [ -f www/.env ] || error "www/.env not found. Configure your Laravel environment first."
    [ -f docker/nginx/certs/default.crt ] || error "SSL cert not found. Use a Cloudflare Origin CA certificate (recommended) or generate a self-signed cert:
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \\
      -keyout docker/nginx/certs/default.key \\
      -out docker/nginx/certs/default.crt \\
      -subj \"/CN=\$(grep SITE_URL .env | cut -d= -f2)\"
    See README.md for details."

    # Verify proxy network exists (Traefik must be running)
    docker network inspect proxy >/dev/null 2>&1 || error "proxy network not found. Start the Traefik stack first (cd docker/traefik && docker compose up -d)"
}

fix_permissions() {
    info "Fixing storage permissions"
    source .env
    local uid="${USER_ID:-1000}"
    local gid="${GROUP_ID:-1000}"
    chown -R "$uid:$gid" www/storage www/bootstrap/cache 2>/dev/null || {
        info "Could not chown (not root?). Falling back to chmod."
        chmod -R 775 www/storage www/bootstrap/cache
    }
}

# ---------------------------------------------------------------------------
# First deployment
# ---------------------------------------------------------------------------

first_deploy() {
    check_prereqs

    info "Building images"
    $COMPOSE_CMD build

    fix_permissions

    info "Starting services"
    $COMPOSE_CMD up -d

    info "Waiting for services to be healthy"
    $COMPOSE_CMD exec php php -v >/dev/null 2>&1 || sleep 5

    info "Installing Composer dependencies"
    $COMPOSE_CMD exec php composer install --no-dev --optimize-autoloader

    info "Running migrations"
    $COMPOSE_CMD exec php php artisan migrate --force

    info "Creating storage symlink"
    $COMPOSE_CMD exec php php artisan storage:link 2>/dev/null || true

    info "Caching config"
    $COMPOSE_CMD exec php php artisan config:cache
    $COMPOSE_CMD exec php php artisan route:cache
    $COMPOSE_CMD exec php php artisan view:cache

    info "Building frontend assets"
    $COMPOSE_CMD run --rm nodejs npm ci
    $COMPOSE_CMD run --rm nodejs npm run build

    info "Deployment complete"
    $COMPOSE_CMD ps
}

# ---------------------------------------------------------------------------
# Update deployment (code changes)
# ---------------------------------------------------------------------------

update_deploy() {
    [ -f .env ] || error ".env not found."
    [ -d www ] || error "www/ directory not found."

    info "Pulling latest code"
    (cd www && git pull)

    info "Installing Composer dependencies"
    $COMPOSE_CMD exec php composer install --no-dev --optimize-autoloader

    info "Running migrations"
    $COMPOSE_CMD exec php php artisan migrate --force

    info "Clearing and rebuilding caches"
    $COMPOSE_CMD exec php php artisan config:cache
    $COMPOSE_CMD exec php php artisan route:cache
    $COMPOSE_CMD exec php php artisan view:cache

    info "Building frontend assets"
    $COMPOSE_CMD run --rm nodejs npm ci
    $COMPOSE_CMD run --rm nodejs npm run build

    info "Restarting PHP (clears OPcache)"
    $COMPOSE_CMD restart php

    info "Restarting Horizon"
    $COMPOSE_CMD exec php php artisan horizon:terminate
    # Horizon container auto-restarts via restart: unless-stopped

    info "Update complete"
    $COMPOSE_CMD ps
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

case "${1:-}" in
    update)
        update_deploy
        ;;
    *)
        first_deploy
        ;;
esac
