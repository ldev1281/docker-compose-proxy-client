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
    echo "authentik:"
    read -p "AUTHENTIK_APP_HOSTNAME [${AUTHENTIK_APP_HOSTNAME:-auth.example.com}]: " input
    AUTHENTIK_APP_HOSTNAME=${input:-${AUTHENTIK_APP_HOSTNAME:-auth.example.com}}

    read -p "AUTHENTIK_APP_CONTAINER [${AUTHENTIK_APP_CONTAINER:-authentik-app}]: " input
    AUTHENTIK_APP_CONTAINER=${input:-${AUTHENTIK_APP_CONTAINER:-authentik-app}}

    echo ""
    echo "proxy-client-socat-socks5h-frp:"
    read -p "PROXY_CLIENT_SOCAT_FRP_HOST [${PROXY_CLIENT_SOCAT_FRP_HOST:-frps.onion}]: " input
    PROXY_CLIENT_SOCAT_FRP_HOST=${input:-${PROXY_CLIENT_SOCAT_FRP_HOST:-frps.onion}}

    read -p "PROXY_CLIENT_SOCAT_FRP_PORT [${PROXY_CLIENT_SOCAT_FRP_PORT:-7000}]: " input
    PROXY_CLIENT_SOCAT_FRP_PORT=${input:-${PROXY_CLIENT_SOCAT_FRP_PORT:-7000}}

    read -p "PROXY_CLIENT_SOCAT_FRP_TOKEN [${PROXY_CLIENT_SOCAT_FRP_TOKEN:-$_PROXY_CLIENT_SOCAT_FRP_TOKEN}]: " input
    PROXY_CLIENT_SOCAT_FRP_TOKEN=${input:-${PROXY_CLIENT_SOCAT_FRP_TOKEN:-$_PROXY_CLIENT_SOCAT_FRP_TOKEN}}

    echo ""
    echo "proxy-client-socat-socks5h-dante:"
    read -p "PROXY_CLIENT_SOCAT_DANTE_HOST [${PROXY_CLIENT_SOCAT_DANTE_HOST:-dante.onion}]: " input
    PROXY_CLIENT_SOCAT_DANTE_HOST=${input:-${PROXY_CLIENT_SOCAT_DANTE_HOST:-dante.onion}}

    read -p "PROXY_CLIENT_SOCAT_DANTE_PORT [${PROXY_CLIENT_SOCAT_DANTE_PORT:-1080}]: " input
    PROXY_CLIENT_SOCAT_DANTE_PORT=${input:-${PROXY_CLIENT_SOCAT_DANTE_PORT:-1080}}

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

    echo ""
    echo "no_proxy:"

    default_no_proxy_items=(
        "localhost"
        "127.0.0.1"
        "::1"
        "*.local"
        "*.localhost"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
    )

    # Add all *_APP_CONTAINER variables defined so far
    for var_name in $(compgen -v); do
        if [[ "$var_name" =~ _APP_CONTAINER$ ]]; then
            value="${!var_name}"
            [[ -n "$value" ]] && default_no_proxy_items+=("$value")
        fi
    done

    DEFAULT_NO_PROXY=$(
        IFS=,
        echo "${default_no_proxy_items[*]}"
    )

    read -p "NO_PROXY [${NO_PROXY:-$DEFAULT_NO_PROXY}]: " input
    NO_PROXY=${input:-${NO_PROXY:-$DEFAULT_NO_PROXY}}
}

confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# socat-frp"
        "PROXY_CLIENT_SOCAT_FRP_HOST=${PROXY_CLIENT_SOCAT_FRP_HOST}"
        "PROXY_CLIENT_SOCAT_FRP_PORT=${PROXY_CLIENT_SOCAT_FRP_PORT}"
        "PROXY_CLIENT_SOCAT_FRP_TOKEN=${PROXY_CLIENT_SOCAT_FRP_TOKEN}"
        ""
        "# dante proxy"
        "PROXY_CLIENT_SOCAT_DANTE_HOST=${PROXY_CLIENT_SOCAT_DANTE_HOST}"
        "PROXY_CLIENT_SOCAT_DANTE_PORT=${PROXY_CLIENT_SOCAT_DANTE_PORT}"
        ""
        "# smtp proxy"
        "PROXY_CLIENT_SOCAT_SMTP_HOST=${PROXY_CLIENT_SOCAT_SMTP_HOST}"
        "PROXY_CLIENT_SOCAT_SMTP_PORT=${PROXY_CLIENT_SOCAT_SMTP_PORT}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST}"
        "PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT=${PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT}"
        ""
        "# no_proxy"
        "NO_PROXY=${NO_PROXY}"
        ""
        "# authentik"
        "AUTHENTIK_APP_HOSTNAME=${AUTHENTIK_APP_HOSTNAME}"
        "AUTHENTIK_APP_CONTAINER=${AUTHENTIK_APP_CONTAINER}"
        ""
        "# firefly"
        "FIREFLY_APP_HOSTNAME=${FIREFLY_APP_HOSTNAME}"
        "FIREFLY_APP_CONTAINER=${FIREFLY_APP_CONTAINER}"
        ""
        "# wekan"
        "WEKAN_APP_HOSTNAME=${WEKAN_APP_HOSTNAME}"
        "WEKAN_APP_CONTAINER=${WEKAN_APP_CONTAINER}"
        ""
        "# outline"
        "OUTLINE_APP_HOSTNAME=${OUTLINE_APP_HOSTNAME}"
        "OUTLINE_APP_CONTAINER=${OUTLINE_APP_CONTAINER}"
        ""
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

    printf "%s\n" "${CONFIG_LINES[@]}" >"$ENV_FILE"
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
