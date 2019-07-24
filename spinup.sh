#!/bin/bash

set -e

if [[ $USER != 'root' ]]; then
    echo 'Error: This script must be run as root' 1>&2 && exit 1
fi

num_nodes=$1

if [[ $num_nodes == 0 || $num_nodes > 4 ]]; then
    num_nodes=4
fi

if [[ -z $CLUSTER_UUID ]]; then
    CLUSTER_UUID=$(uuidgen)
fi

nodes=""

for i in $(seq $num_nodes); do
    nodes="$nodes node$i"
done

CLUSTER_UUID=$CLUSTER_UUID docker-compose up -d $nodes

function cleanup() {
    docker-compose stop
    docker rm $(docker-compose ps -q | tr '\n' ' ') > /dev/null
    rm -rf /tmp/couchbase-cluster-$CLUSTER_UUID > /dev/null
}

trap cleanup SIGINT

sleep 15 # wait for the couchbase nodes to initialise

if [[ $num_nodes == 1 ]]; then
    curl -s -X POST http://172.20.1.1:8091/settings/web -d 'username=admin&password=password&port=SAME' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/pools/default -d 'memoryQuota=512' -d 'indexMemoryQuota=256' -d 'ftsMemoryQuota=256' -d 'cbasMemoryQuota=1024' -d 'eventingMemoryQuota=256' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/settings/indexes -d 'storageMode=plasma' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/node/controller/setupServices -d 'services=kv%2Cindex%2Cfts%2Cn1ql%2Ccbas%2Ceventing' > /dev/null
else
    curl -s -X POST http://172.20.1.1:8091/settings/web -d 'username=admin&password=password&port=SAME' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/pools/default -d 'memoryQuota=512' -d 'indexMemoryQuota=256' -d 'ftsMemoryQuota=256' -d 'cbasMemoryQuota=1024' -d 'eventingMemoryQuota=256' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/settings/indexes -d 'storageMode=plasma' > /dev/null
    curl -s -u admin:password http://172.20.1.1:8091/node/controller/setupServices -d 'services=kv' > /dev/null

    for node in $(seq 2 $num_nodes); do
        if [[ $node == $num_nodes ]]; then
            curl -s -u admin:password 172.20.1.1:8091/controller/addNode -d "hostname=172.20.1.$node" -d 'user=admin' -d 'password=password' -d 'services=index%2Cfts%2Cn1ql%2Ccbas%2Ceventing' > /dev/null
        else
            curl -s -u admin:password 172.20.1.1:8091/controller/addNode -d "hostname=172.20.1.$node" -d 'user=admin' -d 'password=password' -d 'services=kv' > /dev/null
        fi
    done
fi

known_nodes=""

for node in $(seq $num_nodes); do
    known_nodes+="ns_1%40172.20.1.$node"

    if [[ $node != $num_nodes ]]; then
        known_nodes+="%2C"
    fi
done

curl -s -u admin:password 172.20.1.1:8091/controller/rebalance -d "knownNodes=$known_nodes" > /dev/null

while true; do
    docker wait $(docker-compose ps -q | tr '\n' ' ') &> /dev/null
done
