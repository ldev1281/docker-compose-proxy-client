#!/bin/sh

set -e

mkdir -p /etc/caddy

echo -n >/etc/caddy/Caddyfile

# --- Keycloak ---
if [ -n "$KEYCLOAK_APP_HOSTNAME" ]; then
    echo "[+] Generating config for Keycloak"
    echo "# Auto-generated Keycloak config" >>/etc/caddy/Caddyfile

    export KEYCLOAK_APP_HOST="${KEYCLOAK_APP_HOST:-keycloak-app}"
    export KEYCLOAK_APP_HTTP_PORT="${KEYCLOAK_APP_HTTP_PORT:-8080}"

    {
        echo "${KEYCLOAK_APP_HOSTNAME} {"
        echo "    reverse_proxy ${KEYCLOAK_APP_HOST}:${KEYCLOAK_APP_HTTP_PORT}"
        echo "}"

    } >>/etc/caddy/Caddyfile

    echo "" >>/etc/caddy/Caddyfile
else
    echo "[ ] Skipping Keycloak — KEYCLOAK_APP_HOSTNAME is not set"
fi

# --- Firefly ---
if [ -n "$FIREFLY_APP_HOSTNAME" ]; then
    echo "[+] Generating config for Firefly"
    echo "# Auto-generated Firefly config" >>/etc/caddy/Caddyfile

    export FIREFLY_APP_HOST="${FIREFLY_APP_HOST:-firefly-app}"
    export FIREFLY_APP_HTTP_PORT="${FIREFLY_APP_HTTP_PORT:-8080}"

    {
        echo "${FIREFLY_APP_HOSTNAME} {"
        echo "    reverse_proxy ${FIREFLY_APP_HOST}:${FIREFLY_APP_HTTP_PORT}"
        echo "}"

    } >>/etc/caddy/Caddyfile

    echo "" >>/etc/caddy/Caddyfile
else
    echo "[ ] Skipping Firefly — FIREFLY_APP_HOSTNAME is not set"
fi

# --- Wekan ---
if [ -n "$WEKAN_APP_HOSTNAME" ]; then
    echo "[+] Generating config for Wekan"
    echo "# Auto-generated Wekan config" >>/etc/caddy/Caddyfile

    export WEKAN_APP_HOST="${WEKAN_APP_HOST:-wekan-app}"
    export WEKAN_APP_HTTP_PORT="${WEKAN_APP_HTTP_PORT:-8080}"

    {
        echo "${WEKAN_APP_HOSTNAME} {"
        echo "    reverse_proxy ${WEKAN_APP_HOST}:${WEKAN_APP_HTTP_PORT}"
        echo "}"

    } >>/etc/caddy/Caddyfile

    echo "" >>/etc/caddy/Caddyfile
else
    echo "[ ] Skipping Wekan — WEKAN_APP_HOSTNAME is not set"
fi

# --- Outline example ---
if [ -n "$OUTLINE_APP_HOSTNAME" ]; then
    echo "[+] Generating config for Outline"
    echo "# Auto-generated Outline config" >>/etc/caddy/Caddyfile

    export OUTLINE_APP_HOST="${OUTLINE_APP_HOST:-outline-app}"
    export OUTLINE_APP_PORT="${OUTLINE_APP_PORT:-3000}"

    {
        echo "${OUTLINE_APP_HOSTNAME} {"
        echo "    reverse_proxy ${OUTLINE_APP_HOST}:${OUTLINE_APP_PORT}"
        echo "}"
    } >>/etc/caddy/Caddyfile

    echo "" >>/etc/caddy/Caddyfile
else
    echo "[ ] Skipping Outline — OUTLINE_APP_HOSTNAME is not set"
fi

if [ ! -s /etc/caddy/Caddyfile ]; then
    echo "[i] No services enabled, using default response"
    echo "# Default response auto-generated config" >>/etc/caddy/Caddyfile
    {
        echo ":80 {"
        echo "    respond \"Caddy is running, but no services are configured.\" 200"
        echo "}"
    } >>/etc/caddy/Caddyfile
fi

echo "[✓] Final Caddyfile generated:"
cat /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile