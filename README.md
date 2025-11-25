# Caddy Reverse Proxy Docker Compose Deployment

This repository provides a production-ready Docker Compose configuration for deploying the Caddy reverse proxy to securely manage traffic routing to backend services and external networks.

---

## Setup Instructions

### 1. Download and Extract the Release

Download the packaged release to your server into the `/docker/proxy-client/` directory and extract it there.

Create the target directory and enter it:

```bash
mkdir -p /docker/proxy-client
cd /docker/proxy-client
```

You can either download the **latest** release:

```bash
curl -fsSL "https://github.com/ldev1281/docker-compose-proxy-client/releases/latest/download/docker-compose-proxy-client.tar.gz" -o /tmp/docker-compose-proxy-client.tar.gz
tar xzf /tmp/docker-compose-proxy-client.tar.gz -C /docker/proxy-client
rm -f /tmp/docker-compose-proxy-client.tar.gz
```

Or download a **specific** release (for example `2025.1.100100`):

```bash
curl -fsSL "https://github.com/ldev1281/docker-compose-proxy-client/releases/download/2025.1.100100/docker-compose-proxy-client.tar.gz" -o /tmp/docker-compose-proxy-client.tar.gz
tar xzf /tmp/docker-compose-proxy-client.tar.gz -C /docker/proxy-client
rm -f /tmp/docker-compose-proxy-client.tar.gz
```

After extraction, the contents of the archive should be located directly in `/docker/proxy-client/` next to `docker-compose.yml`.

---

### 2. Create Required Docker Networks

Caddy proxy-client communicates with backend services through isolated internal networks.

Create the required networks (if missing):

```bash
docker network create --driver bridge --internal proxy-client-authentik
docker network create --driver bridge --internal proxy-client-firefly
docker network create --driver bridge --internal proxy-client-youtrack
docker network create --driver bridge --internal proxy-client-gitlab
```

---

### 3. Configure and Start the Application

The Caddyfile located at `./vol/proxy-client-caddy/etc/caddy/Caddyfile` is dynamically rendered from environment variables.

Configuration Variables:

| Variable Name | Description | Default Value |
|--------------|-------------|---------------|
| `PROXY_HOST` | Remote proxy hostname | `example.onion` |
| `PROXY_FRP_PORT` | Remote FRP server port | `7000` |
| `PROXY_FRP_TOKEN` | FRP authentication token | *(required)* |
| `PROXY_SOCKS5H_PORT` | External SOCKS5h port (for SMTP) | `1080` |
| `PROXY_CLIENT_CADDY_VERSION` | Caddy version | `2.10.0` |
| `PROXY_CLIENT_CADDY_NO_PROXY` | Bypass list | `localhost,127.0.0.1,...` |
| `PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME` | Authentik public domain | `authentik-app.example.com` |
| `PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER` | Authentik internal hostname | `authentik-app` |
| `PROXY_CLIENT_CADDY_FIREFLY_APP_HOSTNAME` | Firefly public domain | `firefly-app.example.com` |
| `PROXY_CLIENT_CADDY_FIREFLY_APP_CONTAINER` | Firefly internal hostname | `firefly-app` |
| `PROXY_CLIENT_CADDY_YOUTRACK_APP_HOSTNAME` | YouTrack public domain | `youtrack-app.example.com` |
| `PROXY_CLIENT_CADDY_YOUTRACK_APP_CONTAINER` | YouTrack internal hostname | `youtrack-app` |
| `PROXY_CLIENT_CADDY_GITLAB_APP_HOSTNAME` | GitLab public domain | `gitlab-app.example.com` |
| `PROXY_CLIENT_CADDY_GITLAB_APP_CONTAINER` | GitLab internal hostname | `gitlab-app` |
| `PROXY_CLIENT_CADDY_REGISTRY_APP_HOSTNAME` | Docker Registry public domain | `registry.example.com` |
| `PROXY_CLIENT_CADDY_REGISTRY_APP_CONTAINER` | Docker Registry internal hostname | `gitlab-app` |
| `PROXY_CLIENT_SMTP_HOST` | External SMTP server | `smtp.mailgun.org` |
| `PROXY_CLIENT_SMTP_PORT` | SMTP port | `587` |

To start the configuration workflow:

```bash
./tools/init.bash
```

---

### 4. Start the Proxy-Client Service

```bash
docker compose up -d
```

---

### 5. Verify Running Containers

```bash
docker compose ps
```

---

### 6. Persistent Data Storage

Caddy uses the following volumes:

- `./vol/proxy-client-caddy/data` — ACME certificates  
- `./vol/proxy-client-caddy/config` — runtime configuration  
- `./usr/local/bin/entrypoint.sh` — custom entrypoint  

---

### Example Directory Structure

```
/docker/proxy-client/
├── docker-compose.yml
├── tools/
│   └── init.bash
├── usr/
│   └── local/
│       └── bin/
│           └── entrypoint.sh
├── vol/
│   └── proxy-client-caddy/
│       ├── data/
│       ├── config/
│       └── etc/
│           └── caddy/
│               └── Caddyfile
└── .env
```

---

## Creating a Backup Task for Proxy-Client

Create a task:

```bash
sudo nano /etc/limbo-backup/rsync.conf.d/20-proxy-client.conf.bash
```

Insert:

```bash
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
```

---

## License

Licensed under the Prostokvashino License. See `LICENSE` for details.
