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
    rm -rf /tmp/couchbase-cluster-$CLUSTER_UUID > /dev/null
}

trap cleanup SIGINT

sleep 15 # wait for the couchbase nodes to initialise

if [[ $num_nodes == "1" ]]; then
    curl -s -X POST http://172.20.1.1:8091/clusterInit -d 'username=Administrator&password=asdasd&port=SAME&services=kv%2Cindex%2Cfts%2Cn1ql%2Ccbas%2Ceventing%2Cbackup&memoryQuota=512&indexMemoryQuota=256&ftsMemoryQuota=256&cbasMemoryQuota=1024&eventingMemoryQuota=256' > /dev/null
    curl -s -u Administrator:asdasd http://172.20.1.1:8091/settings/indexes -d 'storageMode=plasma' > /dev/null
else
    curl -s -X POST http://172.20.1.1:8091/clusterInit -d 'username=Administrator&password=asdasd&port=SAME&services=kv&memoryQuota=512&indexMemoryQuota=256&ftsMemoryQuota=256&cbasMemoryQuota=1024&eventingMemoryQuota=256' > /dev/null
    curl -s -u Administrator:asdasd http://172.20.1.1:8091/settings/indexes -d 'storageMode=plasma' > /dev/null

    for node in $(seq 2 $num_nodes); do
        if [[ $node == $num_nodes ]]; then
            curl -s -u Administrator:asdasd 172.20.1.1:8091/controller/addNode -d "hostname=172.20.1.$node" -d 'user=Administrator' -d 'password=asdasd' -d 'services=index%2Cfts%2Cn1ql%2Ccbas%2Ceventing%2Cbackup' > /dev/null
        else
            curl -s -u Administrator:asdasd 172.20.1.1:8091/controller/addNode -d "hostname=172.20.1.$node" -d 'user=Administrator' -d 'password=asdasd' -d 'services=kv' > /dev/null
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

curl -s -u Administrator:asdasd 172.20.1.1:8091/controller/rebalance -d "knownNodes=$known_nodes" > /dev/null

while true; do
    docker wait $(docker-compose ps -q | tr '\n' ' ') &> /dev/null
done
