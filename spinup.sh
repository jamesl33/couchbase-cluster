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

sleep 15 # wait for the couchbase nodes to initialise

curl -s -X POST http://172.20.1.1:8091/pools/default -d 'memoryQuota=512' -d 'indexMemoryQuota=256' -d 'ftsMemoryQuota=256' -d 'cbasMemoryQuota=1024' -d 'eventingMemoryQuota=256' > /dev/null
curl -s -X POST http://172.20.1.1:8091/node/controller/setupServices -d 'services=kv' > /dev/null
curl -s -X POST http://172.20.1.1:8091/settings/web -d 'username=admin&password=password&port=SAME' > /dev/null
curl -s -u admin:password 172.20.1.1:8091/settings/indexes -d 'storageMode=plasma' > /dev/null
curl -s -u admin:password 172.20.1.1:8091/controller/addNode -d 'hostname=172.20.1.2' -d 'user=admin' -d 'password=password' -d 'services=kv' > /dev/null
curl -s -u admin:password 172.20.1.1:8091/controller/addNode -d 'hostname=172.20.1.3' -d 'user=admin' -d 'password=password' -d 'services=kv' > /dev/null
curl -s -u admin:password 172.20.1.1:8091/controller/addNode -d 'hostname=172.20.1.4' -d 'user=admin' -d 'password=password' -d 'services=index%2Cfts%2Cn1ql%2Ccbas%2Ceventing' > /dev/null
curl -s -u admin:password 172.20.1.1:8091/controller/rebalance -d 'knownNodes=ns_1%40172.20.1.1%2Cns_1%40172.20.1.2%2Cns_1%40172.20.1.3%2Cns_1%40172.20.1.4' > /dev/null

while true; do
    docker wait $(docker-compose ps -q | tr '\n' ' ') &> /dev/null
done
