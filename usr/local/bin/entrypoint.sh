#!/bin/sh

set -e

# Default port values
: "${AUTHENTIK_APP_PORT:=9000}"
: "${OUTLINE_APP_PORT:=3000}"

mkdir -p /etc/caddy
: > /etc/caddy/Caddyfile

SERVICES="AUTHENTIK OUTLINE"

for SERVICE in $SERVICES; do
    HOSTNAME_VAR="${SERVICE}_APP_HOSTNAME"
    CONTAINER_VAR="${SERVICE}_APP_CONTAINER"
    PORT_VAR="${SERVICE}_APP_PORT"

    eval HOSTNAME_VALUE="\${${HOSTNAME_VAR}:-}"
    if [ -n "$HOSTNAME_VALUE" ]; then
        echo "[+] Generating config for $SERVICE"
        echo "# Auto-generated ${SERVICE} config" >> /etc/caddy/Caddyfile


        eval ": \${${CONTAINER_VAR}?Missing ${CONTAINER_VAR}}"

        eval CONTAINER_VALUE="\$$CONTAINER_VAR"
        eval PORT_VALUE="\$$PORT_VAR"
        {
            echo "${HOSTNAME_VALUE} {"
            echo "    reverse_proxy ${CONTAINER_VALUE}:${PORT_VALUE}"
            echo "}"
            echo ""
        } >> /etc/caddy/Caddyfile
    else
        echo "[ ] Skipping $SERVICE — ${HOSTNAME_VAR} is not set or empty"
    fi
done

if [ ! -s /etc/caddy/Caddyfile ]; then
    echo "[i] No services enabled, using default response"
    echo "# Default response auto-generated config" >> /etc/caddy/Caddyfile
    {
        echo ":80 {"
        echo "    respond \"Caddy is running, but no services are configured.\" 200"
        echo "}"
    } >> /etc/caddy/Caddyfile
fi

echo "[✓] Final Caddyfile generated:"
cat /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
