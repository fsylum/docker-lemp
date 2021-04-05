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
* Mailhog

Software available within `php` service:

* Composer
* WP-CLI

## Requirement

* [Docker Compose](https://docs.docker.com/compose/install/) - Please follow the installation instruction specific to your OS

## Installation

* Clone the repository to your local computer
* Copy `.env.sample` to `.env`
* Configure the setup (see **Configuration** section for a more detailed information)
* Run `docker-compose up -d` (see **Usage** section for a more detailed information)
* Add new entry in your OS host file

## Configuration

The `.env.sample` file is heavily commented which should be enough to get started. However, here are some remarks for the configurations:

* Ideally `COMPOSE_PROJECT_NAME` is set to something unique to differentiate between multiple projects.
* A few ports are exposed by default for (see configuration keys ended with `_PORT`):
    * Nginx (both HTTP and HTTPS connection)
    * Mailhog (Web UI)
    * MySQL
* Any versions listed on Docker Hub technically are supported, but the `alpine` specific version is preferable due to smaller image size.
* The `SITE_NAME` configuration is for the URL of the site without the protocol. You should also add the related entry in the host file of your OS.
* Two services are disabled by default (`scheduler `and `worker`). If you need to use any of these services, make sure to uncomment the related section in `docker-compose.yml`.
* Cron job is managed using the `docker/scheduler/config.ini` file. Check the related documentation on the [project page](https://github.com/mcuadros/ofelia) on how to manage a schedule.

## Usage

Once the configuration is done, all of standard Docker Compose commands can be used for the project.

* To start all services in detached mode, run `docker-compose up -d`.
* To stop all services, run `docker-compose down`.
* To inspect all runing services, run `docker-compose ps`.
* You can also start/stop each services manually, by running `docker-compose start <service>` and `docker-compose stop <service>`.
* To run a specific command inside the service, use `docker-compose exec <service> <command>`. For example, to check the PHP version inside the `php` service, run `docker-compose exec php php -v`.
* If the service is not running (for example `nodejs`), use `docker-compose run --rm <service> <command>` instead. For example, to check the installed Node.js version in the `nodejs` service, run `docker-compose run --rm nodejs node -v`.

See [Overview of Docker Compose](https://docs.docker.com/compose/) for more information.

## Accessing the site

Assuming a configuration with `SITE_NAME` set to `docker.test` and the related entry in host file is added, you can access your site on

* http://docker.test - Assuming `NGINX_PORT_UNSECURE` is set to 80, otherwise append the port number to the URL.
* https://docker.test - If the `SITE_IS_SECURE` configuration set to `true`, assuming `NGINX_PORT_SECURE` is set to 443, otherwise append the port number to the URL.
* http://docker.test:8025 - Mailhog UI, assuming the `MAILHOG_PORT` is set to `8025`.

## Accessing the database

Depending on the configuration for `MYSQL_PORT`, you can connect to the database from your machine by connecting to `127.0.0.1` and the `MYSQL_PORT` configured as it's automatically forwarded from the `mysql` service.

## Customizing the services

All files within the `docker` directory can be edited to suit your requirement, and it's currently named identical to the related services in `docker-compose.yml` file. After the file is updated, make sure to rebuild the service once again to make sure the changes are taking effect.

```
docker-compose build <service-name>
docker-compose up -d
```

## Miscellaneous

### Laravel specific configuration

For Laravel-specific site, please follow these steps to enable queue worker and cron scheduler.

1. Uncomment the `scheduler` service in the `docker-compose.yml`. Make sure to also check the `container` value in the `docker/scheduler/config.ini` to match your Docker configuration.
2. Uncomment the `worker` service in the `docker-compose.yml`. This is currently using multi-stage Docker build to run a separate instance of `php` service that specifically run the `artisan queue:work` command inside the container.
3. Uncomment the last two lines in the `docker/php/Dockerfile` to enable a separate worker service.

## Troubleshooting

### Getting error `the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty' when running docker-compose exec <container> sh`

If you're running the command in the Git bash, you might need to prefix `winpty` to all the commands you want to run. For this example, you can run it by `winpty docker-compose exec <container> sh` instead.
