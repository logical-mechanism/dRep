#!/usr/bin/env bash
set -e

cli=$(cat ./data/path_to_cli.sh)
network=$(cat ./data/network.sh)

if [[ $# -eq 0 ]] ; then
    echo 'Please Supply A Wallet Folder'
    exit 1
fi

folder=${1}

if [ ! -d ${folder} ]; then
    mkdir ${folder}
    ${cli} conway address key-gen --verification-key-file ${folder}/payment.vkey --signing-key-file ${folder}/payment.skey
    ${cli} conway address build --payment-verification-key-file ${folder}/payment.vkey --out-file ${folder}/payment.addr ${network}
    ${cli} conway address key-hash --payment-verification-key-file ${folder}/payment.vkey --out-file ${folder}/payment.hash
else
    echo "Folder already exists"
    exit 1
fi
