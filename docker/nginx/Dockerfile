ARG NGINX_VERSION=1.27-alpine

FROM nginx:$NGINX_VERSION

ARG SITE_URL=docker-lemp.test
ARG SITE_TYPE=default

COPY stubs /etc/nginx/h5bp
COPY certs /etc/nginx/certs

RUN mv /etc/nginx/h5bp/mime.types /etc/nginx/mime.types
RUN mv /etc/nginx/h5bp/nginx.conf /etc/nginx/nginx.conf
RUN mv /etc/nginx/h5bp/default.conf /etc/nginx/conf.d/default.conf;
RUN sed -i "s|{{SITE_URL}}|$SITE_URL|g" /etc/nginx/conf.d/default.conf
RUN if [[ "$SITE_TYPE" == "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www/public|g" /etc/nginx/conf.d/default.conf; fi
RUN if [[ "$SITE_TYPE" != "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www|g" /etc/nginx/conf.d/default.conf; fi
