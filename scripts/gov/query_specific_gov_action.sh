#!/usr/bin/env bash
set -e

if [[ $# -eq 0 ]] ; then
    echo -e "\n \033[0;31m Please Supply Goverance TxId \033[0m \n";
    exit
fi

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

${cli} conway query gov-state ${network} --out-file ../data/gov/gov.state

jq -r '.proposals | to_entries[] | select(.value.actionId.txId == "'${1}'") | .value' ../data/gov/gov.state