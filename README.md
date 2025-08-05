# Caddy Reverse Proxy Docker Compose Deployment

This repository contains a Docker Compose configuration for deploying the Caddy reverse proxy to manage multiple backend services securely.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/proxy-client-caddy/` directory:

```
mkdir -p /docker/proxy-client-caddy
cd /docker/proxy-client-caddy
git clone https://github.com/ldev1281/docker-compose-proxy-client.git .
```

### 2. Review Docker Compose Configuration

Key service:

- `proxy-client-caddy`: A lightweight, extensible web server acting as a reverse proxy with automatic HTTPS.

The Proxy-client-caddy container is connected to the `proxy-client-universe` network for public access. Additional networks (e.g., `proxy-client-authentik`, `proxy-client-firefly`, `proxy-client-wekan`, `proxy-client-outline`) are used for private communication with backend services.

**Create required external Docker networks** (if they do not already exist):

```bash
docker network create --driver bridge proxy-client-authentik
docker network create --driver bridge proxy-client-firefly
docker network create --driver bridge proxy-client-wekan
docker network create --driver bridge proxy-client-outline
   ```


### 3. Configure and Start the Application

The Caddyfile `./vol/proxy-client-caddy/etc/caddy/Caddyfile` is dynamically generated using the environment variables.

Configuration Variables:
| Variable Name                              | Description                                                                                                 | Default Value              |
|--------------------------------------------|-------------------------------------------------------------------------------------------------------------|----------------------------|
| `PROXY_CLIENT_SOCAT_FRP_HOST`              | Hostname of remote FRP (reverse proxy) server                                                               | `frps.onion`               |
| `PROXY_CLIENT_SOCAT_FRP_PORT`              | Port exposed by remote FRP server                                                                           | `7000`                     |
| `PROXY_CLIENT_SOCAT_FRP_TOKEN`             | Shared secret used for FRP authentication                                                                   | *(use token from frps)*    |
| `PROXY_CLIENT_SOCAT_DANTE_HOST`            | Hostname of Dante SOCKS5 proxy server for external HTTP connections                                         | `dante.onion`              |
| `PROXY_CLIENT_SOCAT_DANTE_PORT`            | Port exposed by Dante proxy server for external HTTP connections                                            | `1080`                     |
| `PROXY_CLIENT_SOCAT_SMTP_HOST`             | External SMTP server hostname                                                                               | `smtp.example.com`         |
| `PROXY_CLIENT_SOCAT_SMTP_PORT`             | External SMTP port (usually 587 for STARTTLS or 465 for SSL)                                                | `587`                      |
| `PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_HOST`     | Hostname of SOCKS5 proxy server for external SMTP connection (usually the same as for Dante proxy server)   | `dante.onion`              |
| `PROXY_CLIENT_SOCAT_SMTP_SOCKS5H_PORT`     | Port exposed by SOCKS5 proxy server for external SMTP connection (usually the same as for Dante proxy)      | `1080`                     |
| `NO_PROXY`                                 | Comma-separated list of hosts/IPs to exclude from proxy                                                     | `localhost,127.0.0.1,...`  |
| `AUTHENTIK_APP_HOSTNAME`                   | Public domain name for Authentik                                                                            | `auth.example.com`         |
| `AUTHENTIK_APP_CONTAINER`                  | Internal container hostname for Authentik service                                                           | `authentik-app`            |
| `FIREFLY_APP_HOSTNAME`                     | Public domain name for Firefly III                                                                          | `firefly.example.com`      |
| `FIREFLY_APP_CONTAINER`                    | Internal container hostname for Firefly service                                                             | `firefly-app`              |
| `WEKAN_APP_HOSTNAME`                       | Public domain name for Wekan                                                                                | `wekan.example.com`        |
| `WEKAN_APP_CONTAINER`                      | Internal container hostname for Wekan service                                                               | `wekan-app`                |
| `OUTLINE_APP_HOSTNAME`                     | Public domain name for Outline                                                                              | `outline.example.com`      |
| `OUTLINE_APP_CONTAINER`                    | Internal container hostname for Outline service                                                             | `outline-app`              |


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

This will start proxy-client-caddy and make your configured domains available.

### 5. Verify Running Containers

```
docker compose ps
```

You should see the `proxy-client-caddy` container running.

### 6. Persistent Data Storage

Caddy stores ACME certificates, account keys, and other important data in the following volumes:

- `./vol/proxy-client-caddy/data:/data` – ACME certificates and keys
- `./vol/proxy-client-caddy/config:/config` – Runtime configuration and state
- `./usr/local/bin/entrypoint.sh` – Custom entrypoint script

Make sure these directories are backed up to avoid losing certificates and configuration.

---

### Example Directory Structure

```
/docker/proxy-client-caddy/
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


## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.