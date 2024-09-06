#!/usr/bin/env bash
set -e

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

${cli} conway query gov-state ${network} --out-file ../data/gov/gov.state

jq -r '.proposals' ../data/gov/gov.state