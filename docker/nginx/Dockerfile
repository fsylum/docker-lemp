ARG NGINX_VERSION

FROM nginx:$NGINX_VERSION

ARG SITE_URL
ARG SITE_IS_SECURE
ARG SITE_TYPE

COPY stubs /etc/nginx/snippets/h5bp

RUN apk --update --no-cache add openssl
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj /CN=$SITE_URL -keyout /tmp/default.key -out /tmp/default.crt
RUN mkdir -p /etc/nginx/certs
RUN mv /tmp/default.key /etc/nginx/certs
RUN mv /tmp/default.crt /etc/nginx/certs
RUN mv /etc/nginx/snippets/h5bp/mime.types /etc/nginx/mime.types
RUN mv /etc/nginx/snippets/h5bp/nginx.conf /etc/nginx/nginx.conf
RUN mv /etc/nginx/snippets/h5bp/templates/default.conf /etc/nginx/conf.d/default.conf;
RUN sed -i "s|{{SITE_URL}}|$SITE_URL|g" /etc/nginx/conf.d/default.conf
RUN if [[ "$SITE_TYPE" == "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www/public|g" /etc/nginx/conf.d/default.conf; fi
RUN if [[ "$SITE_TYPE" != "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www|g" /etc/nginx/conf.d/default.conf; fi
