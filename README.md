# abc
# Caddy Reverse Proxy Docker Compose Deployment

This repository contains a Docker Compose configuration for deploying the Caddy reverse proxy to manage multiple backend services securely, as well as to handle connections to external networks.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/proxy-client/` directory:

```
mkdir -p /docker/proxy-client
cd /docker/proxy-client
git clone https://github.com/ldev1281/docker-compose-proxy-client.git .
```

### 2. Review Docker Compose Configuration

Key service:

- `proxy-client`: A lightweight, extensible web server acting as a reverse proxy with automatic HTTPS.

The Proxy-client container is connected to the `proxy-client-universe` network for public access. Additional networks (e.g., `proxy-client-authentik`) are used for private communication with backend services.

**Create required external Docker networks** (if they do not already exist):

```bash
docker network create --driver bridge --internal proxy-client-authentik
docker network create --driver bridge --internal proxy-client-firefly
docker network create --driver bridge --internal proxy-client-youtrack
docker network create --driver bridge --internal proxy-client-gitlab
```


### 3. Configure and Start the Application

The Caddyfile `./vol/proxy-client-caddy/etc/caddy/Caddyfile` is dynamically generated using the environment variables.

Configuration Variables:

| Variable Name                                 | Description                                                                | Default Value               |
|-----------------------------------------------|----------------------------------------------------------------------------|-----------------------------|
| `PROXY_HOST`                                  | Hostname of the remote proxy server                                        | `example.onion`             |
| `PROXY_FRP_PORT`                              | Port exposed by remote FRP server                                          | `7000`                      |
| `PROXY_FRP_TOKEN`                             | Shared secret used for FRP authentication                                  | *(use token from frps)*     |
| `PROXY_SOCKS5H_PORT`                          | Port exposed by SOCKS5 proxy server for external SMTP connection           | `1080`                      |
| `PROXY_CLIENT_CADDY_VERSION`                  | Version of Caddy to use                                                    | `2.10.0`                    |
| `PROXY_CLIENT_CADDY_NO_PROXY`                 | Comma-separated list of hosts/IPs to exclude from proxy                    | `localhost,127.0.0.1,...`   |
| `PROXY_CLIENT_CADDY_AUTHENTIK_APP_HOSTNAME`   | Public domain name for Authentik                                           | `authentik-app.example.com` |
| `PROXY_CLIENT_CADDY_AUTHENTIK_APP_CONTAINER`  | Internal container hostname for Authentik service                          | `authentik-app`             |
| `PROXY_CLIENT_CADDY_FIREFLY_APP_HOSTNAME`     | Public domain name for Firefly                                             | `firefly-app.example.com`   |
| `PROXY_CLIENT_CADDY_FIREFLY_APP_CONTAINER`    | Internal container hostname for Firefly service                            | `firefly-app`               |
| `PROXY_CLIENT_CADDY_YOUTRACK_APP_HOSTNAME`    | Public domain name for YouTrack                                            | `youtrack-app.example.com`  |
| `PROXY_CLIENT_CADDY_YOUTRACK_APP_CONTAINER`   | Internal container hostname for YouTrack service                           | `youtrack-app`              |
| `PROXY_CLIENT_CADDY_GITLAB_APP_HOSTNAME`      | Public domain name for GitLab                                              | `gitlab-app.example.com`    |
| `PROXY_CLIENT_CADDY_GITLAB_APP_CONTAINER`     | Internal container hostname for GitLab service                             | `gitlab-app`                |
| `PROXY_CLIENT_CADDY_REGISTRY_APP_HOSTNAME`    | Public domain name for Docker Registry                                     | `registry.example.com`      |
| `PROXY_CLIENT_CADDY_REGISTRY_APP_CONTAINER`   | Internal container hostname for Docker Registry service                    | `gitlab-app`                |
| `PROXY_CLIENT_SMTP_HOST`                      | External SMTP server hostname                                              | `smtp.mailgun.org`          |
| `PROXY_CLIENT_SMTP_PORT`                      | External SMTP port (usually 587 for STARTTLS or 465 for SSL)               | `587`                       |

To configure and launch all required services, run the provided script:

```bash
./tools/init.bash
```

The script will:

- Prompt you to enter configuration values (press `Enter` to accept defaults).
- Generate secure random secrets automatically.
- Save all settings to the `.env` file located at the project root.

**Important:**  
Make sure to securely store your `.env` file locally for future reference or redeployment.


### 4. Start the proxy-client Service

```
docker compose up -d
```

This will start proxy-client and make your configured domains available.

### 5. Verify Running Containers

```
docker compose ps
```

You should see the `proxy-client` containers running.

### 6. Persistent Data Storage

Caddy stores ACME certificates, account keys, and other important data in the following volumes:

- `./vol/proxy-client-caddy/data:/data` – ACME certificates and keys
- `./vol/proxy-client-caddy/config:/config` – Runtime configuration and state
- `./usr/local/bin/entrypoint.sh` – Custom entrypoint script

Make sure these directories are backed up to avoid losing certificates and configuration.

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

To create a backup task for your proxy-client deployment using [`backup-tool`](https://github.com/ldev1281/backup-tool), add a new task file to `/etc/limbo-backup/rsync.conf.d/`:

```bash
sudo nano /etc/limbo-backup/rsync.conf.d/20-proxy-client.conf.bash
```

Paste the following contents:

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

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.
# abc2