#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol/"

generate_defaults() {
    _PROXY_CLIENT_SOCAT_FRP_TOKEN=$(openssl rand -hex 32)
}

load_existing_env() {
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
}

prompt_for_configuration() {
    echo "Enter configuration values (press Enter to keep current/default value):"
    echo ""

    echo "proxy-client-socat-socks5h-frp:"
    read -p "PROXY_CLIENT_SOCAT_FRP_HOST [${PROXY_CLIENT_SOCAT_FRP_HOST:-frps.onion}]: " input
    PROXY_CLIENT_SOCAT_FRP_HOST=${input:-${PROXY_CLIENT_SOCAT_FRP_HOST:-frps.onion}}

    read -p "PROXY_CLIENT_SOCAT_FRP_PORT [${PROXY_CLIENT_SOCAT_FRP_PORT:-7000}]: " input
    PROXY_CLIENT_SOCAT_FRP_PORT=${input:-${PROXY_CLIENT_SOCAT_FRP_PORT:-7000}}

    read -p "PROXY_CLIENT_SOCAT_FRP_TOKEN [${PROXY_CLIENT_SOCAT_FRP_TOKEN:-$_PROXY_CLIENT_SOCAT_FRP_TOKEN}]: " input
    PROXY_CLIENT_SOCAT_FRP_TOKEN=${input:-${PROXY_CLIENT_SOCAT_FRP_TOKEN:-$_PROXY_CLIENT_SOCAT_FRP_TOKEN}}

    echo ""
    echo "keycloak:"
    read -p "KEYCLOAK_APP_HOSTNAME [${KEYCLOAK_APP_HOSTNAME:-auth.example.com}]: " input
    KEYCLOAK_APP_HOSTNAME=${input:-${KEYCLOAK_APP_HOSTNAME:-auth.example.com}}

    read -p "KEYCLOAK_APP_HOST [${KEYCLOAK_APP_HOST:-keycloak-app}]: " input
    KEYCLOAK_APP_HOST=${input:-${KEYCLOAK_APP_HOST:-keycloak-app}}

    echo ""
    echo "firefly:"
    read -p "FIREFLY_APP_HOSTNAME [${FIREFLY_APP_HOSTNAME:-firefly.example.com}]: " input
    FIREFLY_APP_HOSTNAME=${input:-${FIREFLY_APP_HOSTNAME:-firefly.example.com}}

    read -p "FIREFLY_APP_HOST [${FIREFLY_APP_HOST:-firefly-app}]: " input
    FIREFLY_APP_HOST=${input:-${FIREFLY_APP_HOST:-firefly-app}}

    echo ""
    echo "wekan:"
    read -p "WEKAN_APP_HOSTNAME [${WEKAN_APP_HOSTNAME:-wekan.example.com}]: " input
    WEKAN_APP_HOSTNAME=${input:-${WEKAN_APP_HOSTNAME:-wekan.example.com}}

    read -p "WEKAN_APP_HOST [${WEKAN_APP_HOST:-wekan-app}]: " input
    WEKAN_APP_HOST=${input:-${WEKAN_APP_HOST:-wekan-app}}

    echo ""
    echo "outline:"
    read -p "OUTLINE_APP_HOSTNAME [${OUTLINE_APP_HOSTNAME:-outline.example.com}]: " input
    OUTLINE_APP_HOSTNAME=${input:-${OUTLINE_APP_HOSTNAME:-outline.example.com}}

    read -p "OUTLINE_APP_HOST [${OUTLINE_APP_HOST:-outline-app}]: " input
    OUTLINE_APP_HOST=${input:-${OUTLINE_APP_HOST:-outline-app}}

    echo ""
    echo "proxy-client-socat-socks5h-dante:"
    read -p "PROXY_CLIENT_SOCAT_DANTE_HOST [${PROXY_CLIENT_SOCAT_DANTE_HOST:-dante.onion}]: " input
    PROXY_CLIENT_SOCAT_DANTE_HOST=${input:-${PROXY_CLIENT_SOCAT_DANTE_HOST:-dante.onion}}

    read -p "PROXY_CLIENT_SOCAT_DANTE_PORT [${PROXY_CLIENT_SOCAT_DANTE_PORT:-1080}]: " input
    PROXY_CLIENT_SOCAT_DANTE_PORT=${input:-${PROXY_CLIENT_SOCAT_DANTE_PORT:-1080}}

    read -p "PROXY_CLIENT_SOCAT_DANTE_USER [${PROXY_CLIENT_SOCAT_DANTE_USER:-proxyuser}]: " input
    PROXY_CLIENT_SOCAT_DANTE_USER=${input:-${PROXY_CLIENT_SOCAT_DANTE_USER:-proxyuser}}

    read -p "PROXY_CLIENT_SOCAT_DANTE_PASSWORD [${PROXY_CLIENT_SOCAT_DANTE_PASSWORD:-proxypass}]: " input
    PROXY_CLIENT_SOCAT_DANTE_PASSWORD=${input:-${PROXY_CLIENT_SOCAT_DANTE_PASSWORD:-proxypass}}

    echo ""
    echo "proxy-client-socat-socks5h-smtp:"
    read -p "PROXY_CLIENT_SOCAT_SMTP_HOST [${PROXY_CLIENT_SOCAT_SMTP_HOST:-smtp.example.com}]: " input
    PROXY_CLIENT_SOCAT_SMTP_HOST=${input:-${PROXY_CLIENT_SOCAT_SMTP_HOST:-smtp.example.com}}

    read -p "PROXY_CLIENT_SOCAT_SMTP_PORT [${PROXY_CLIENT_SOCAT_SMTP_PORT:-587}]: " input
    PROXY_CLIENT_SOCAT_SMTP_PORT=${input:-${PROXY_CLIENT_SOCAT_SMTP_PORT:-587}}

    read -p "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST [${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST:-$PROXY_CLIENT_SOCAT_DANTE_HOST}]: " input
    PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST=${input:-${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST:-$PROXY_CLIENT_SOCAT_DANTE_HOST}}

    read -p "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT [${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT:-$PROXY_CLIENT_SOCAT_DANTE_PORT}]: " input
    PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT=${input:-${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT:-$PROXY_CLIENT_SOCAT_DANTE_PORT}}

    read -p "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER [${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER:-$PROXY_CLIENT_SOCAT_DANTE_USER}]: " input
    PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER=${input:-${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER:-$PROXY_CLIENT_SOCAT_DANTE_USER}}

    read -p "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD [${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD:-$PROXY_CLIENT_SOCAT_DANTE_PASSWORD}]: " input
    PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD=${input:-${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD:-$PROXY_CLIENT_SOCAT_DANTE_PASSWORD}}
}

confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# socat-frp"
        "PROXY_CLIENT_SOCAT_FRP_HOST=${PROXY_CLIENT_SOCAT_FRP_HOST}"
        "PROXY_CLIENT_SOCAT_FRP_PORT=${PROXY_CLIENT_SOCAT_FRP_PORT}"
        "PROXY_CLIENT_SOCAT_FRP_TOKEN=${PROXY_CLIENT_SOCAT_FRP_TOKEN}"
        ""
        "# keycloak"
        "KEYCLOAK_APP_HOSTNAME=${KEYCLOAK_APP_HOSTNAME}"
        "KEYCLOAK_APP_HOST=${KEYCLOAK_APP_HOST}"
        ""
        "# firefly"
        "FIREFLY_APP_HOSTNAME=${FIREFLY_APP_HOSTNAME}"
        "FIREFLY_APP_HOST=${FIREFLY_APP_HOST}"
        ""
        "# wekan"
        "WEKAN_APP_HOSTNAME=${WEKAN_APP_HOSTNAME}"
        "WEKAN_APP_HOST=${WEKAN_APP_HOST}"
        ""
        "# outline"
        "OUTLINE_APP_HOSTNAME=${OUTLINE_APP_HOSTNAME}"
        "OUTLINE_APP_HOST=${OUTLINE_APP_HOST}"
        ""
        "# dante proxy"
        "PROXY_CLIENT_SOCAT_DANTE_HOST=${PROXY_CLIENT_SOCAT_DANTE_HOST}"
        "PROXY_CLIENT_SOCAT_DANTE_PORT=${PROXY_CLIENT_SOCAT_DANTE_PORT}"
        "PROXY_CLIENT_SOCAT_DANTE_USER=${PROXY_CLIENT_SOCAT_DANTE_USER}"
        "PROXY_CLIENT_SOCAT_DANTE_PASSWORD=${PROXY_CLIENT_SOCAT_DANTE_PASSWORD}"
        ""
        "# smtp proxy"
        "PROXY_CLIENT_SOCAT_SMTP_HOST=${PROXY_CLIENT_SOCAT_SMTP_HOST}"
        "PROXY_CLIENT_SOCAT_SMTP_PORT=${PROXY_CLIENT_SOCAT_SMTP_PORT}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_USER}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PASSWORD}"
    )

    echo ""
    echo "Configuration to be saved:"
    echo "---------------------------"
    printf "%s\n" "${CONFIG_LINES[@]}"
    echo "---------------------------"
    echo ""

    read -p "Save this configuration to .env? (y/n): " CONFIRM
    echo ""
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Aborted."
        exit 1
    fi

    printf "%s\n" "${CONFIG_LINES[@]}" > "$ENV_FILE"
    echo ".env saved to $ENV_FILE"
    echo ""
}

setup_containers() {
    echo "Stopping containers and removing volumes..."
    docker compose down -v

    echo "Clearing volumes..."
    [ -d "$VOL_DIR" ] && rm -rf "${VOL_DIR:?}"/*

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 60 seconds for initialization..."
    sleep 60

    echo "Done!"
}

# --- main ---
if [ -f "$ENV_FILE" ]; then
    echo ".env found. Loading..."
    load_existing_env
else
    echo ".env not found. Generating defaults..."
    generate_defaults
fi

prompt_for_configuration
confirm_and_save_configuration
setup_containers