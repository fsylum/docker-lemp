A simple Docker-based LEMP stack for local web development using Docker Compose.

## What's Included

This setup comes with eight services out of the box.

* Nginx
* PHP
* MySQL
* Node.js
* Scheduler  - based on [mcuadros/ofelia](https://github.com/mcuadros/ofelia)
* Redis
* Memcached
* Mailpit

Software available within `php` service:

* Composer
* WP-CLI

## Requirement

* [Docker Compose](https://docs.docker.com/compose/) - Please follow the installation instruction specific to your OS

## Installation

* Clone the repository.
* Copy `.env.sample` to `.env`.
* Configure the setup (see **Configuration** section for a more detailed information).
* Run `docker compose up -d` (see **Usage** section for a more detailed information).
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

* To start all services in detached mode, run `docker compose up -d`.
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

## Troubleshooting

### Getting error `the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty' when running docker compose exec <container> sh`

If you're running the command in the Git bash, you might need to prefix `winpty` to all the commands you want to run. For this example, you can run it by `winpty docker compose exec <container> sh` instead.
