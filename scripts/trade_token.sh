#!/usr/bin/env bash
set -e
#
rm tmp/tx.signed || true
export CARDANO_NODE_SOCKET_PATH=$(cat ./data/path_to_socket.sh)
cli=$(cat ./data/path_to_cli.sh)
network=$(cat ./data/network.sh)

# Addresses
sender_path="wallets/batcher-wallet/"
sender_address=$(cat ${sender_path}payment.addr)
# receiver_address=$(cat wallets/seller-wallet/payment.addr)
# receiver_address=${sender_address}
# receiver_address=$(jq -r '.starterChangeAddr' ../config.json)
receiver_address=""
#
# exit
#
echo -e "\033[0;36m Gathering UTxO Information  \033[0m"
${cli} conway query utxo \
    ${network} \
    --address ${sender_address} \
    --out-file tmp/sender_utxo.json

TXNS=$(jq length tmp/sender_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${sender_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/sender_utxo.json)
sender_tx_in=${TXIN::-8}
echo Sender UTxO: ${sender_tx_in}

# exit

echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} conway transaction build \
    --out-file tmp/tx.draft \
    --change-address ${receiver_address} \
    --tx-in ${sender_tx_in} \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"

echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} conway transaction sign \
    --signing-key-file ${sender_path}payment.skey \
    --tx-body-file tmp/tx.draft \
    --out-file tmp/tx.signed \
    ${network}
#
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} conway transaction submit \
    ${network} \
    --tx-file tmp/tx.signed

tx=$(cardano-cli transaction txid --tx-file tmp/tx.signed)
echo "Tx Hash:" $tx