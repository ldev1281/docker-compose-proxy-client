CMD_BEFORE_BACKUP="docker compose --project-directory /docker/proxy-client down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/proxy-client up -d"
CMD_BEFORE_RESTORE="docker compose --project-directory /docker/proxy-client stop"
CMD_AFTER_RESTORE="docker compose --project-directory /docker/proxy-client start"

INCLUDE_PATHS=(
  "/docker/proxy-client/.env"
)