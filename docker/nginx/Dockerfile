ARG NGINX_VERSION

FROM nginx:$NGINX_VERSION

ARG SITE_NAME
ARG SITE_IS_SECURE
ARG SITE_TYPE

COPY stubs /etc/nginx/snippets/h5bp

RUN if [[ "$SITE_IS_SECURE" = true ]] ; then apk --update --no-cache add openssl; fi
RUN if [[ "$SITE_IS_SECURE" = true ]] ; then openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj /CN=$SITE_NAME -keyout /tmp/default.key -out /tmp/default.crt; fi
RUN if [[ "$SITE_IS_SECURE" = true ]] ; then mkdir -p /etc/nginx/certs; fi
RUN if [[ "$SITE_IS_SECURE" = true ]] ; then mv /tmp/default.key /etc/nginx/certs; fi
RUN if [[ "$SITE_IS_SECURE" = true ]] ; then mv /tmp/default.crt /etc/nginx/certs; fi
RUN mv /etc/nginx/snippets/h5bp/mime.types /etc/nginx/mime.types
RUN mv /etc/nginx/snippets/h5bp/nginx.conf /etc/nginx/nginx.conf
RUN if [[ "$SITE_IS_SECURE" = true ]] ; then mv /etc/nginx/snippets/h5bp/templates/default-ssl.conf /etc/nginx/conf.d/default.conf; else mv /etc/nginx/snippets/h5bp/templates/default.conf /etc/nginx/conf.d/default.conf; fi
RUN sed -i "s|{{SITE_NAME}}|$SITE_NAME|g" /etc/nginx/conf.d/default.conf
RUN if [[ "$SITE_TYPE" == "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www/public|g" /etc/nginx/conf.d/default.conf; fi
RUN if [[ "$SITE_TYPE" != "laravel" ]] ; then sed -i "s|{{DOCUMENT_ROOT}}|/srv/www|g" /etc/nginx/conf.d/default.conf; fi
