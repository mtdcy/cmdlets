# syntax=docker/dockerfile:1
FROM ubuntu:latest

USER buildbot
WORKDIR /cmdlets
COPY --chown=buildbot . /cmdlets

RUN ./.github/scripts/build.sh
