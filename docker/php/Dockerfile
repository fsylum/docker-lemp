ARG PHP_VERSION=8.4-fpm-alpine

FROM php:$PHP_VERSION

ARG COMPOSER_VERSION=2.8.5
ARG MAILPIT_VERSION=1.22.3
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG SITE_TYPE=default

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN apk --update --no-cache add jpegoptim optipng pngquant gifsicle
RUN install-php-extensions bcmath exif gd gettext intl json ldap mysqli odbc pcntl pdo pdo_mysql pdo_pgsql pdo_sqlite pgsql pspell readline redis simplexml soap spl standard xmlrpc zip
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=$COMPOSER_VERSION
RUN curl -Lo /tmp/mailpit.tar.gz https://github.com/axllent/mailpit/releases/download/v$MAILPIT_VERSION/mailpit-linux-amd64.tar.gz && tar -xf /tmp/mailpit.tar.gz -C /usr/local/bin && chmod +x /usr/local/bin/mailpit
RUN mkdir -p /.config/composer
RUN chown -R $USER_ID:$GROUP_ID /.config/composer
RUN if [[ "$SITE_TYPE" == "wordpress" ]] ; then curl -Lo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; fi
RUN if [[ "$SITE_TYPE" == "wordpress" ]] ; then chmod +x /usr/local/bin/wp; fi
RUN if [[ "$SITE_TYPE" == "wordpress" ]] ; then mkdir -p /.wp-cli; fi
RUN if [[ "$SITE_TYPE" == "wordpress" ]] ; then chown -R $USER_ID:$GROUP_ID /.wp-cli; fi
RUN if [[ "$SITE_TYPE" == "laravel" ]] ; then mkdir -p /.config/psysh; fi
RUN if [[ "$SITE_TYPE" == "laravel" ]] ; then chown -R $USER_ID:$GROUP_ID /psysh; fi

COPY stubs/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Enable this section for Laravel
#FROM php AS worker
#CMD ["php", "/srv/www/artisan", "queue:work"]
