#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol/"
BACKUP_TASKS_SRC_DIR="${SCRIPT_DIR}/../etc/limbo-backup/rsync.conf.d"
BACKUP_TASKS_DST_DIR="/etc/limbo-backup/rsync.conf.d"

REQUIRED_TOOLS="docker limbo-backup.bash"
REQUIRED_NETS="proxy-client-authentik proxy-client-outline"
BACKUP_TASKS="10-proxy-client.conf.bash"

check_requirements() {
    missed_tools=()
    for cmd in $REQUIRED_TOOLS; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missed_tools+=("$cmd")
        fi
    done

    if ((${#missed_tools[@]})); then
        echo "Required tools not found:" >&2
        for cmd in "${missed_tools[@]}"; do
            echo "  - $cmd" >&2
        done
        echo "Hint: run dev-prod-init.recipe from debian-setup-factory" >&2
        echo "Abort"
        exit 127
    fi
}

create_networks() {
    for net in $REQUIRED_NETS; do
        if docker network inspect "$net" >/dev/null 2>&1; then
            echo "Required network already exists: $net"
        else
            echo "Creating required docker network: $net (driver=bridge)"
            docker network create --driver bridge "$net" >/dev/null
        fi
    done
}

create_backup_tasks() {
    for task in $BACKUP_TASKS; do
        src_file="${BACKUP_TASKS_SRC_DIR}/${task}"
        dst_file="${BACKUP_TASKS_DST_DIR}/${task}"

        if [[ ! -f "$src_file" ]]; then
            echo "Warning: backup task not found: $src_file" >&2
            continue
        fi

        cp "$src_file" "$dst_file"
        echo "Created backup task: $dst_file"
    done
}

generate_defaults() {
    _PROXY_FRP_TOKEN=$(openssl rand -hex 32)
}

load_existing_env() {
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
}

prompt_for_configuration() {
    echo "Enter configuration values (press Enter to keep current/default value):"
    echo ""
    echo "Proxy settings:"
    read -p "PROXY_HOST [${PROXY_HOST:-example.onion}]: " input
    PROXY_HOST=${input:-${PROXY_HOST:-example.onion}}

    echo ""
    echo "frp:"
    read -p "PROXY_FRP_PORT [${PROXY_FRP_PORT:-7000}]: " input
    PROXY_FRP_PORT=${input:-${PROXY_FRP_PORT:-7000}}

    read -p "PROXY_FRP_TOKEN [${PROXY_FRP_TOKEN:-$_PROXY_FRP_TOKEN}]: " input
    PROXY_FRP_TOKEN=${input:-${PROXY_FRP_TOKEN:-$_PROXY_FRP_TOKEN}}

    echo ""
    echo "socks5h:"
    read -p "PROXY_SOCKS5H_PORT [${PROXY_SOCKS5H_PORT:-1080}]: " input
    PROXY_SOCKS5H_PORT=${input:-${PROXY_SOCKS5H_PORT:-1080}}

    echo "Container specific settings:"
    echo ""
    echo "proxy-client-caddy:"
    read -p "PROXY_CLIENT_CADDY_VERSION [${PROXY_CLIENT_CADDY_VERSION:-2.10.0}]: " input
    PROXY_CLIENT_CADDY_VERSION=${input:-${PROXY_CLIENT_CADDY_VERSION:-2.10.0}}

    read -p "PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME [${PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME:-authentik-app.example.com}]: " input
    PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME=${input:-${PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME:-authentik-app.example.com}}

    read -p "PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER [${PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER:-authentik-app}]: " input
    PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER=${input:-${PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER:-authentik-app}}

    read -p "PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME [${PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME:-outline-app.example.com}]: " input
    PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME=${input:-${PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME:-outline-app.example.com}}

    read -p "PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER [${PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER:-outline-app}]: " input
    PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER=${input:-${PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER:-outline-app}}

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

    read -p "PROXY_CLIENT_CADDY_NO_PROXY [${PROXY_CLIENT_CADDY_NO_PROXY:-$DEFAULT_NO_PROXY}]: " input
    PROXY_CLIENT_CADDY_NO_PROXY=${input:-${PROXY_CLIENT_CADDY_NO_PROXY:-$DEFAULT_NO_PROXY}}

    echo ""
    echo "proxy-client-smtp:"
    read -p "PROXY_CLIENT_SMTP_HOST [${PROXY_CLIENT_SMTP_HOST:-smtp.mailgun.org}]: " input
    PROXY_CLIENT_SMTP_HOST=${input:-${PROXY_CLIENT_SMTP_HOST:-smtp.mailgun.org}}

    read -p "PROXY_CLIENT_SMTP_PORT [${PROXY_CLIENT_SMTP_PORT:-587}]: " input
    PROXY_CLIENT_SMTP_PORT=${input:-${PROXY_CLIENT_SMTP_PORT:-587}}
}

confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# Proxy settings"
        "PROXY_HOST=${PROXY_HOST}"
        ""
        "# frp"
        "PROXY_FRP_PORT=${PROXY_FRP_PORT}"
        "PROXY_FRP_TOKEN=${PROXY_FRP_TOKEN}"
        ""
        "# socks5h"
        "PROXY_SOCKS5H_PORT=${PROXY_SOCKS5H_PORT}"
        ""
        ""
        ""
        "# Container specific settings"
        "#"
        "#"
        ""
        "# proxy-client-caddy"
        "PROXY_CLIENT_CADDY_VERSION=${PROXY_CLIENT_CADDY_VERSION}"
        "PROXY_CLIENT_CADDY_NO_PROXY=${PROXY_CLIENT_CADDY_NO_PROXY}"
        "PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME=${PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME}"
        "PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER=${PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER}"
        "PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME=${PROXY_CLIENT_CADDY_OUTLINE_APP_HOSTNAME}"
        "PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER=${PROXY_CLIENT_CADDY_OUTLINE_APP_CONTAINER}"
        ""
        "# proxy-client-smtp"
        "PROXY_CLIENT_SMTP_HOST=${PROXY_CLIENT_SMTP_HOST}"
        "PROXY_CLIENT_SMTP_PORT=${PROXY_CLIENT_SMTP_PORT}"
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
check_requirements

if [ -f "$ENV_FILE" ]; then
    echo ".env found. Loading..."
    load_existing_env
else
    echo ".env not found. Generating defaults..."
    generate_defaults
fi

prompt_for_configuration
confirm_and_save_configuration
create_networks
create_backup_tasks
setup_containers
