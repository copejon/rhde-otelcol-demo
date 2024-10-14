#!/bin/bash
set -eu


# DEFAULTS
RELEASE=latest
DATA_DIR=/var/run/user/$(id -u)/grafana-lgtm/container
WIPE_DATA=false

LOG_GRAF=
LOG_PROM=
LOG_OTEL=

while getopts "r:d:wgpo" OPTION "${@}"; do
    case "${OPTION}" in
        r)
            RELEASE="${OPTARG}"
            ;;
        d)
            DATA_DIR="${OPTARG}"
            ;;
        w)
            WIPE_DATA=true
            ;;
        g)
            LOG_GRAF="-e ENABLE_LOGS_GRAFANA=true"
            ;;
        p)
            LOG_PROM="-e ENALBE_LOGS_PROMETHEUS=true"
            ;;
        o)
            LOG_OTEL="-e ENABLE_LOGS_OTELCOL=true"
            ;;
    esac 
done


if $WIPE_DATA; then
    rm -rf $DATA_DIR
fi

if ! [ -d $DATA_DIR ]; then
    mkdir -p $DATA_DIR/{grafana,prometheus,loki}
fi

podman run \
    --name lgtm \
    -p 3000:3000 \
    -p 4317:4317 \
    -p 4318:4318 \
    --rm \
    -ti \
    -v ${DATA_DIR}/grafana:/data/grafana:Z \
    -v ${DATA_DIR}/prometheus:/data/prometheus:Z \
    -v ${DATA_DIR}/loki:/loki:Z \
    -e GF_PATHS_DATA=/data/grafana \
    ${LOG_GRAF:-$LOG_GRAF} \
    ${LOG_PROM:-$LOG_PROM} \
    ${LOG_OTEL:-$LOG_OTEL} \
    docker.io/grafana/otel-lgtm:${RELEASE}
