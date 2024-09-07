#!/usr/bin/env bash
set -e

if [[ $# -ne 2 ]] ; then
    echo -e "\n \033[0;31m Please Supply Goverance TxId and TxIdx \033[0m \n";
    exit
fi

# Validate the first argument (string)
if [[ ! "$1" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "Error: First argument must be a string."
    exit 1
fi

# Validate the second argument (number)
if ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: Second argument must be a number."
    exit 1
fi

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

${cli} conway query gov-state ${network} --out-file ../data/gov/gov.state

jq -r '.proposals | to_entries[] | select(.value.actionId.txId == "'${1}'" and .value.actionId.govActionIx == '${2}') | .value' ../data/gov/gov.state