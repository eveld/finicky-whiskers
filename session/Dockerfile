FROM ruby:2.6.6-alpine as builder

RUN apk add -u curl make

WORKDIR /app
VOLUME /app

ENTRYPOINT [ "make" ]