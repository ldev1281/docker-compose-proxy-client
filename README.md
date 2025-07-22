# Caddy Reverse Proxy Docker Compose Deployment

This repository contains a Docker Compose configuration for deploying the Caddy reverse proxy to manage multiple backend services securely.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/caddy/` directory:

```
mkdir -p /docker/caddy
cd /docker/caddy
git clone https://github.com/ldev1281/docker-compose-caddy.git .
```

### 2. Review Docker Compose Configuration

Key service:

- `caddy`: A lightweight, extensible web server acting as a reverse proxy with automatic HTTPS.

The Caddy container is connected to the `caddy-universe` network for public access. Additional networks (e.g., `caddy-keycloak`, `caddy-firefly`, `caddy-wekan`) are used for private communication with backend services.

**Create required external Docker networks** (if they do not already exist):

```bash
docker network create --driver bridge caddy-keycloak
docker network create --driver bridge caddy-firefly
docker network create --driver bridge caddy-wekan
   ```


### 3. Configure and Start the Application

The Caddyfile `./vol/caddy/etc/caddy/Caddyfile` is dynamically generated using the environment variables.

Configuration Variables:

| Variable Name             | Description                                                        | Default Value                   |
|---------------------------|--------------------------------------------------------------------|----------------------------------|
| `FRP_HOST`                | Remote FRP (reverse proxy) host address                            | `.onion`                         |
| `FRP_PORT`                | Port number for FRP server                                         | `7000`                           |
| `FRP_TOKEN`               | Shared secret used for FRP authentication                          | *(use token from frps)*          |
| `KEYCLOAK_APP_HOSTNAME`   | Public domain name for Keycloak                                    | `auth.example.com`              |
| `KEYCLOAK_APP_HOST`       | Internal container hostname for Keycloak service                   | `keycloak-app`                  |
| `FIREFLY_APP_HOSTNAME`    | Public domain name for Firefly III                                 | `firefly.example.com`           |
| `FIREFLY_APP_HOST`        | Internal container hostname for Firefly service                    | `firefly-app`                   |
| `WEKAN_APP_HOSTNAME`      | Public domain name for Wekan                                       | `wekan.example.com`             |
| `WEKAN_APP_HOST`          | Internal container hostname for Wekan service                      | `wekan-app`                     |
| `CADDY_DANTE_HOST`        | Hostname of Dante SOCKS5 proxy container (used by Caddy)           | `caddy-socat-dante`             |
| `CADDY_DANTE_PORT`        | Port exposed by Dante proxy container                              | `1080`                          |
| `CADDY_DANTE_USER`        | Username for Dante SOCKS5 authentication                           | `proxyuser`                      |
| `CADDY_DANTE_PASSWORD`    | Password for Dante SOCKS5 authentication                           | `proxypass`                      |


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


### 4. Start the Caddy Service

```
docker compose up -d
```

This will start Caddy and make your configured domains available.

### 5. Verify Running Containers

```
docker compose ps
```

You should see the `caddy` container running.

### 6. Persistent Data Storage

Caddy stores ACME certificates, account keys, and other important data in the following volumes:

- `./vol/caddy/data:/data` – ACME certificates and keys
- `./vol/caddy/config:/config` – Runtime configuration and state
- `./usr/local/bin/caddy-entrypoint.sh` – Custom entrypoint script

Make sure these directories are backed up to avoid losing certificates and configuration.

---

### Example Directory Structure

```
/docker/caddy/
├── docker-compose.yml
├── tools/
│   └── init.bash
├── usr/
│   └── local/
│       └── bin/
│           └── caddy-entrypoint.sh
├── vol/
│   └── caddy/
│       ├── data/
│       ├── config/
│       └── etc/
│           └── caddy/
│               └── Caddyfile
└── .env
```


## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.