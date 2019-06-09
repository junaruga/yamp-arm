# base image
# https://hub.docker.com/r/multiarch/fedora/tags
ARG ARCH
ARG OS_VERSION
FROM multiarch/fedora:${OS_VERSION}-${ARCH} AS base

ENV PATH "/usr/local/bin:${PATH}"
WORKDIR /build
RUN uname -a
COPY install-rpm-pkgs.sh .
RUN ./install-rpm-pkgs.sh
