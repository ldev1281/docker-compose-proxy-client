CMD_BEFORE_BACKUP="docker compose --project-directory /docker/proxy-client down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/proxy-client up -d"

CMD_AFTER_RESTORE="docker compose --project-directory /docker/proxy-client restart"

INCLUDE_PATHS=(
  "/docker/proxy-client"
)
