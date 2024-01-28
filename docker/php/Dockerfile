ARG PHP_VERSION

FROM php:$PHP_VERSION AS php

ARG COMPOSER_VERSION
ARG MHSENDMAIL_VERSION
ARG USER_ID
ARG GROUP_ID

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN apk --update --no-cache add jpegoptim optipng pngquant gifsicle less
RUN install-php-extensions bcmath exif gd gettext intl json ldap mysqli odbc pcntl pdo pdo_mysql pdo_pgsql pdo_sqlite pgsql pspell readline redis simplexml soap spl standard xmlrpc zip
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version="$COMPOSER_VERSION"
RUN curl -Lo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /usr/local/bin/wp
RUN sh < <(curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh)
RUN mkdir -p /.config/composer
RUN mkdir -p /.config/psysh
RUN mkdir -p /.wp-cli
RUN chown -R $USER_ID:$GROUP_ID /.config/composer
RUN chown -R $USER_ID:$GROUP_ID /.config/psysh
RUN chown -R $USER_ID:$GROUP_ID /.wp-cli

COPY stubs/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Enable this section for Laravel
#FROM php AS worker
#CMD ["php", "/srv/www/artisan", "queue:work"]
