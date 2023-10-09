# syntax = docker/dockerfile:1.2
#choose a base image
#FROM julia:1.9.3
FROM julia:1.9.3-alpine

# mark it with a label, so we can remove dangling images
LABEL cicd="qbittorrentstats"

#https://vsupalov.com/buildkit-cache-mount-dockerfile/
ENV PIP_CACHE_DIR=/var/cache/buildkit/pip
RUN mkdir -p $PIP_CACHE_DIR
RUN rm -f /etc/apt/apt.conf.d/docker-clean
#RUN --mount=type=cache,target=/var/cache/apt apt-get update && apt-get install -yqq --no-install-recommends wget git iputils-ping && rm -rf /var/lib/apt/lists/*

ENV TZ="Europe/Zurich" USER=root USER_HOME_DIR=/home/${USER} JULIA_DEPOT_PATH=${USER_HOME_DIR}/.julia NOTEBOOK_DIR=${USER_HOME_DIR}/notebooks JULIA_NUM_THREADS=1

#copy Julia package
RUN mkdir -p /usr/local/qBittorrentStats.jl
COPY . /usr/local/qBittorrentStats.jl

#set workdir
WORKDIR /usr/local/qBittorrentStats.jl

#install dependencies 
RUN julia /usr/local/qBittorrentStats.jl/deps/dockerdeps.jl

########################################################################
#enviroment variables
########################################################################
ARG INFLUXDB_ORG
ENV INFLUXDB_ORG $INFLUXDB_ORG

ARG INFLUXDB_TOKEN
ENV INFLUXDB_TOKEN $INFLUXDB_TOKEN

ARG INFLUXDB_URL
ENV INFLUXDB_URL $INFLUXDB_URL

ARG QBITTORRENT_PASSWORD
ENV QBITTORRENT_PASSWORD $QBITTORRENT_PASSWORD

########################################################################
#run Tests
########################################################################
RUN julia --project=@. -e "import Pkg;Pkg.test()"

########################################################################
#run application 
########################################################################
USER root
#start julia script
#ENTRYPOINT ["julia", "-p 1"]
ENTRYPOINT ["julia"]
CMD ["src/infinite_loop.jl"]
#working dir is set as qBittorrentStats.jl