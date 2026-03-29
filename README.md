A Docker-based LEMP stack for Laravel development and production deployment using Docker Compose.

## What's Included

* Nginx
* PHP
* MySQL
* Node.js
* Horizon (queue worker)
* Scheduler (cron)
* Redis
* Memcached
* Mailpit (dev only)

Software available within `php` service:

* Composer

## Requirement

* [Docker Compose](https://docs.docker.com/compose/) - Please follow the installation instruction specific to your OS

## Installation

* Clone the repository.
* Copy `.env.sample` to `.env`.
* Configure the setup (see **Configuration** section for a more detailed information).
* Run `docker compose --profile dev up -d` (see **Usage** section for a more detailed information).
* Add new entry in your OS host file based on your `SITE_URL` value.
* Generate a new SSL certs using `mkcert` via:

```
mkcert -cert-file docker/nginx/certs/default.crt -key-file docker/nginx/certs/default.key <SITE_URL>
```

## Configuration

The `.env.sample` file is heavily commented which should be enough to get started. However, here are some remarks for the configurations:

* Ideally `COMPOSE_PROJECT_NAME` is set to something unique to differentiate between multiple projects.
* A few ports are exposed by default for (see configuration keys ended with `_PORT`):
    * Nginx (both HTTP and HTTPS connection)
    * Mailpit (Web UI)
    * MySQL
* Any versions listed on Docker Hub technically are supported, but the `alpine` specific version is preferable due to smaller image size.
* The `SITE_URL` configuration is for the URL of the site without the protocol. You should also add the related entry in the host file of your OS.

## Usage

Once the configuration is done, all of standard Docker Compose commands can be used for the project.

* To start all services in detached mode, run `docker compose --profile dev up -d`. The `dev` profile includes dev-only services like Mailpit.
* To stop all services, run `docker compose down`.
* To inspect all running services, run `docker compose ps`.
* You can also start/stop each services manually, by running `docker compose start <service>` and `docker compose stop <service>`.
* To run a specific command inside the service, use `docker compose exec <service> <command>`. For example, to check the PHP version inside the `php` service, run `docker compose exec php php -v`.
* If the service is not running (for example `nodejs`), use `docker compose run --rm <service> <command>` instead. For example, to check the installed Node.js version in the `nodejs` service, run `docker compose run --rm nodejs node -v`.

See [Overview of Docker Compose](https://docs.docker.com/compose/) for more information.

## Accessing the site

Assuming a configuration with `SITE_NAME` set to `docker-lemp.test` and the related entry in host file is added, you can access your site on

* http://docker-lemp.test - Assuming `NGINX_PORT_UNSECURE` is set to 80, otherwise append the port number to the URL.
* https://docker-lemp.test - If the `SITE_IS_SECURE` configuration set to `true`, assuming `NGINX_PORT_SECURE` is set to 443, otherwise append the port number to the URL.
* http://docker-lemp.test:8025 - Mailpit UI, assuming the `MAILPIT_WEB_PORT` is set to `8025`.

## Accessing the database

Depending on the configuration for `MYSQL_PORT`, you can connect to the database from your machine by connecting to `127.0.0.1` and the `MYSQL_PORT` configured as it's automatically forwarded from the `mysql` service.

## Customizing the services

All files within the `docker` directory can be edited to suit your requirement, and it's currently named identical to the related services in `docker-compose.yml` file. After the file is updated, make sure to rebuild the service once again to make sure the changes are taking effect.

```
docker compose build <service-name>
docker compose up -d
```

## Production Deployment

This setup supports multi-site production deployment on a single VPS using Cloudflare Tunnel and Traefik as a shared reverse proxy.

### Architecture

```
Internet → Cloudflare (SSL/CDN/DDoS protection)
         → Cloudflare Tunnel (encrypted)
         → cloudflared container on VPS
         → Traefik (routes by hostname)
           ├→ project-1/nginx → php
           ├→ project-2/nginx → php
           └→ project-3/nginx → php
```

### Initial VPS Setup (once per server)

#### 1. Create a Cloudflare Tunnel

* Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels → Create a tunnel.
* Name the tunnel (e.g. `my-vps`).
* Copy the tunnel token.

#### 2. Start the Traefik stack

```
cd docker/traefik
cp .env.sample .env
```

Set the `CLOUDFLARE_TUNNEL_TOKEN` in `.env` to the token from step 1, then start the stack:

```
docker compose up -d
```

This creates the shared `proxy` network that all projects will join.

#### 3. Configure tunnel hostnames

In the Cloudflare tunnel settings, add a **public hostname** for each site you want to host:

| Public hostname | Service |
|----------------|---------|
| `example.com` | `https://traefik:443` |
| `www.example.com` | `https://traefik:443` |
| `foobar.com` | `https://traefik:443` |

For each hostname, enable **No TLS Verify** under the TLS settings (the origin uses self-signed certificates internally).

#### 4. DNS

Each domain must be added to Cloudflare. The tunnel will create CNAME records automatically, or you can set them manually:

```
example.com     → CNAME → <tunnel-id>.cfargotunnel.com (Proxied)
www.example.com → CNAME → <tunnel-id>.cfargotunnel.com (Proxied)
```

### Per-Site Deployment

Each site is a full clone of this repo with its own containers:

```
/srv/example.com/           ← clone of this repo
├── .env                    ← Docker config
├── docker-compose.yml
├── docker-compose.prod.yml
├── deploy.sh
├── docker/
├── logs/
└── www/                    ← your Laravel app
    └── .env                ← Laravel config
```

#### 1. Clone and configure

```
git clone <repo-url> /srv/example.com
cd /srv/example.com
cp .env.sample .env
```

Set the `.env` values for production:

```
COMPOSE_PROJECT_NAME=example
SITE_URL=example.com
COMPOSE_PROFILES=
BIND_ADDRESS=127.0.0.1
MYSQL_DATABASE=example
MYSQL_USER=example
MYSQL_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-password>
```

`COMPOSE_PROJECT_NAME` must be unique across all projects on the VPS. `BIND_ADDRESS=127.0.0.1` ensures ports are not publicly accessible (traffic goes through Traefik/tunnel only). `COMPOSE_PROFILES` is left empty to exclude dev-only services (Mailpit).

#### 2. Set up your Laravel app

```
git clone <your-laravel-repo> www
cp www/.env.example www/.env
```

Configure `www/.env` for production:

```
APP_ENV=production
APP_DEBUG=false
DB_HOST=mysql
DB_DATABASE=example
DB_USERNAME=example
DB_PASSWORD=<strong-password>
REDIS_HOST=redis
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

#### 3. SSL certificates

Cloudflare handles public SSL. Internally, Nginx needs a certificate for the Traefik connection. The recommended approach is to use a **Cloudflare Origin CA certificate** (free, 15-year validity, verified by Traefik):

1. Go to Cloudflare dashboard → your domain → SSL/TLS → Origin Server → Create Certificate.
2. Keep the defaults (RSA, 15 years). Add your domain(s) to the hostnames list.
3. Save the certificate and private key:

```
# Paste the certificate into:
docker/nginx/certs/default.crt

# Paste the private key into:
docker/nginx/certs/default.key
```

**Alternative:** If you prefer self-signed certs (simpler but less secure):

```
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout docker/nginx/certs/default.key \
  -out docker/nginx/certs/default.crt \
  -subj "/CN=example.com"
```

Note: Self-signed certs require `insecureSkipVerify=true` in the Traefik config (enabled by default).

#### 4. Deploy

```
./deploy.sh
```

This builds images, starts services, installs dependencies, runs migrations, caches config, and builds frontend assets. See `deploy.sh` for the full sequence.

For subsequent deployments (code updates):

```
./deploy.sh update
```

This pulls the latest code, runs migrations, rebuilds caches and assets, restarts PHP (clears OPcache), and restarts Horizon.

### Resource Limits

The production overlay (`docker-compose.prod.yml`) includes resource limits tailored for a 2 CPU / 4GB RAM VPS running a single site:

| Service | Memory | CPU |
|---------|--------|-----|
| MySQL | 512m | 0.5 |
| PHP | 256m | 0.5 |
| Horizon | 256m | 0.5 |
| Nginx | 128m | 0.25 |
| Scheduler | 128m | 0.25 |
| Redis | 64m | 0.25 |
| Memcached | 64m | 0.25 |
| **Total** | **~1.4 GB** | **2.5** |

This leaves headroom for the OS, Traefik, and cloudflared on a 2 CPU / 4GB RAM VPS. If hosting multiple sites, scale the VPS accordingly — each site adds ~1.4 GB. Scale up MySQL, PHP, and Horizon first — they benefit the most.

### Adding More Sites

Repeat the **Per-Site Deployment** steps for each additional site. Then add the corresponding public hostname(s) in the Cloudflare tunnel settings pointing to `https://traefik:443`.

### Log Rotation

Docker container logs (stdout/stderr) are automatically rotated in production via the `json-file` driver (10MB max, 3 files retained).

For volume-mounted application logs (Nginx access/error, PHP slow log, MySQL slow query log), add a host-level logrotate config:

```
sudo tee /etc/logrotate.d/docker-lemp << 'EOF'
/srv/*/logs/nginx/*.log /srv/*/logs/php/*.log /srv/*/logs/mysql/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        for dir in /srv/*/; do
            project=$(basename "$dir")
            docker compose -f "$dir/docker-compose.yml" exec -T nginx nginx -s reopen 2>/dev/null || true
        done
    endscript
}
EOF
```

### Database Backups

A backup script is included at `docker/scripts/backup-db.sh`. It dumps the MySQL database to a compressed file with 7-day retention.

```
chmod +x docker/scripts/backup-db.sh

# Run manually
./docker/scripts/backup-db.sh /srv/example.com

# Set up a daily cron job (3 AM)
crontab -e
0 3 * * * /srv/example.com/docker/scripts/backup-db.sh /srv/example.com >> /var/log/docker-lemp-backup.log 2>&1
```

Backups are stored in `./backups/` and excluded from version control.

### Docker Cleanup

Schedule a weekly cleanup to reclaim disk space from dangling images and stopped containers:

```
crontab -e
0 4 * * 0 docker system prune -f --filter "until=168h" >> /var/log/docker-prune.log 2>&1
```

This removes unused resources older than 7 days. Volumes are **not** pruned to protect database data.

## Troubleshooting

### Getting error `the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty' when running docker compose exec <container> sh`

If you're running the command in the Git bash, you might need to prefix `winpty` to all the commands you want to run. For this example, you can run it by `winpty docker compose exec <container> sh` instead.

### Specific Vite config for Laravel

Add this to the `vite.config.js` file

```
server: {
    https: {
        key: fs.readFileSync(path.resolve(__dirname, '../docker/nginx/certs/default.key')),
        cert: fs.readFileSync(path.resolve(__dirname, '../docker/nginx/certs/default.crt')),
    },
    host: true,
    port: 5173,
},
```

Now you can run `docker compose run --rm -p 5173:5173 nodejs npm run dev`.
