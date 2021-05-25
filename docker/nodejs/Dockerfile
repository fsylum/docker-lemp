ARG NODEJS_VERSION

FROM node:$NODEJS_VERSION

ARG USER_ID
ARG GROUP_ID

RUN mkdir -p /.config/npm
RUN chown -R $USER_ID:$GROUP_ID /.config/npm
