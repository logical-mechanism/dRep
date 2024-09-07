#!/usr/bin/env bash
set -e

## TESTING ONLY

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

net_type=$(python3 -c "x = '${network}'; y = x.split('-magic'); print(y[0])")

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

# who will pay for the tx
hot_address=$(cat ../wallets/hot-wallet/payment.addr)
hot_pkh=$(${cli} conway address key-hash --payment-verification-key-file ../wallets/hot-wallet/payment.vkey)

skh=$(cat "../wallets/delegator-wallet/stake.addr")

# Lets create a info to test
govActionDeposit=$(cat ../tmp/protocol.json | jq -r '.govActionDeposit')
${cli} conway governance action create-info \
    ${net_type} \
    --governance-action-deposit ${govActionDeposit} \
    --deposit-return-stake-address ${skh} \
    --anchor-url https://raw.githubusercontent.com/logical-mechanism/dRep/main/scripts/data/actions/simple.action.json \
    --anchor-data-hash b0ea2fb2fb9a573b8d8b856f861053382e1ef0ca6ecb76cec39c53e94f2c5a29 \
    --out-file ../data/actions/simple.action
#
# exit
#
echo -e "\033[0;36m Gathering Payee UTxO Information  \033[0m"
${cli} conway query utxo \
    ${network} \
    --address ${hot_address} \
    --out-file ../tmp/hot_utxo.json

TXNS=$(jq length ../tmp/hot_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${hot_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'to_entries[] | select(.value.value | length < 2) | .key | . + $alltxin + " --tx-in"' ../tmp/hot_utxo.json)
hot_tx_in=${TXIN::-8}

echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} conway transaction build \
    --out-file ../tmp/tx.draft \
    --change-address ${hot_address} \
    --tx-in ${hot_tx_in} \
    --proposal-file ../data/actions/simple.action \
    --required-signer-hash ${hot_pkh} \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"

echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} conway transaction sign \
    --signing-key-file ../wallets/hot-wallet/payment.skey \
    --signing-key-file ../wallets/delegator-wallet/stake.skey \
    --tx-body-file ../tmp/tx.draft \
    --out-file ../tmp/tx.signed \
    ${network}
#    
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} conway transaction submit \
    ${network} \
    --tx-file ../tmp/tx.signed

tx=$(${cli} conway transaction txid --tx-file ../tmp/tx.signed)
echo "Tx Hash:" $tx