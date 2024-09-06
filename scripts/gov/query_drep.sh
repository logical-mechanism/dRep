#!/usr/bin/env bash
set -e

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

drepHash=$(cat ../../hashes/drep.hash)
${cli} conway query drep-state ${network} --drep-script-hash ${drepHash} --out-file ../data/gov/drep.state
${cli} conway query drep-stake-distribution ${network} --drep-script-hash ${drepHash} --out-file ../data/gov/drep-distro.state

jq -r '' ../data/gov/drep.state

jq -r '' ../data/gov/drep-distro.state