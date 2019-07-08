#!/bin/bash

set -e

if [[ $USER != 'root' ]]; then
    echo 'Error: This script must be run as root' 1>&2 && exit 1
fi

if [[ -z $CLUSTER_UUID ]]; then
    CLUSTER_UUID=$(uuidgen)
fi

CLUSTER_UUID=$CLUSTER_UUID docker-compose up -d "$@"

function cleanup() {
    docker-compose stop
    docker rm $(docker-compose ps -q | tr '\n' ' ') > /dev/null
    rm -rf /tmp/couchbase-cluster-$CLUSTER_UUID > /dev/null
}

trap cleanup SIGINT

while true; do
    docker wait $(docker-compose ps -q | tr '\n' ' ') &> /dev/null
done
