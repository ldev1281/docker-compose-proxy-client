#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol/"
BACKUP_TASKS_SRC_DIR="${SCRIPT_DIR}/../etc/limbo-backup/rsync.conf.d"
BACKUP_TASKS_DST_DIR="/etc/limbo-backup/rsync.conf.d"

REQUIRED_TOOLS="docker limbo-backup.bash"
REQUIRED_NETS="proxy-client-authentik"
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
