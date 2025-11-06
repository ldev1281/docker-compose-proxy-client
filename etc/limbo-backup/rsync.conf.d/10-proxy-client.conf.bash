CMD_BEFORE_BACKUP="docker compose --project-directory /docker/proxy-client down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/proxy-client up -d"

CMD_BEFORE_RESTORE="docker compose --project-directory /docker/proxy-client down || true"
CMD_AFTER_RESTORE=(
"docker network create --driver bridge --internal proxy-client-authentik || true"
"docker network create --driver bridge --internal proxy-client-firefly || true"
"docker network create --driver bridge --internal proxy-client-youtrack || true"
"docker network create --driver bridge --internal proxy-client-gitlab || true"
"docker compose --project-directory /docker/proxy-client up -d"
)

INCLUDE_PATHS=(
  "/docker/proxy-client"
)
