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

## Requirement

* [Docker Compose](https://docs.docker.com/compose/install/)

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
* Any versions listed on Docker Hub technically are supported, but the `alpine` counterpart is preferable due to smaller image size.
* The `SITE_NAME` configuration is for the URL of the site without the protocol. You should also add the related entry in the host file of your OS.
* Two services are disabled by default (`scheduler `and `worker`). If you need to use any of these services, make sure to comment out the related section in `docker-compose.yml`.
* Cron job is managed using the `docker/scheduler/config.ini` file. Check the related documentation on the [project page](https://github.com/mcuadros/ofelia)

## Usage

Once the configuration is done, the standard Docker Compose can be used for the project.

* To start all services in detached mode, run `docker-compose up -d`
* To stop all services, run `docker-compose down`
* You can also start/stop each services manually, by running `docker-compose start <service>` and `docker-compose stop <service>`.
* To run a specific command inside the service, use `docker-compose exec <service> <command>`. For example, to check the PHP version inside the `php` service, run `docker-compose exec php php -v`.
* If the service is not running (for example `nodejs`), use `docker-compose run --rm <service> <command>` instead. For example, to check the installed Node.js version in the `nodejs` service, run `docker-compose run --rm nodejs node -v`.

See [Overview of Docker Compose](https://docs.docker.com/compose/) for more information.

## Miscellaneous

For Laravel-specific site, make sure to comment out the `worker` service in the `docker-compose.yml`. This is currently using multi-stage Docker build to run a separate instance of `php` service that specifically run the `artisan queue:work` command inside the container.

You'll also need to comment out the last section in the file `docker/php/Dockerfile`

```php
# Enable this section for Laravel
#FROM php AS worker

#CMD ["php", "/srv/www/artisan", "queue:work"]
```

