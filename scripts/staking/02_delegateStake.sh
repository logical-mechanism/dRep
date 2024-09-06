#!/usr/bin/env bash
set -e

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

# script
pkh="../wallets/delegator-wallet/payment.vkey"
skh="../wallets/delegator-wallet/stake.vkey"
base_address=$(${cli} conway address build --payment-verification-key-file ${pkh} --stake-verification-key-file ${skh} ${network})
echo $base_address

poolId="1e3105f23f2ac91b3fb4c35fa4fe301421028e356e114944e902005b"
${cli} conway stake-address stake-delegation-certificate --stake-verification-key-file ${skh} --stake-pool-id ${poolId} --out-file ../data/staking/deleg.cert


#
# exit
#

# get payee info
echo -e "\033[0;36m Gathering Payee UTxO Information  \033[0m"
${cli} conway query utxo \
    ${network} \
    --address ${base_address} \
    --out-file ../tmp/payee_utxo.json

TXNS=$(jq length ../tmp/payee_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${base_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' ../tmp/payee_utxo.json)
payee_tx_in=${TXIN::-8}

# exit
echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} conway transaction build \
    --out-file ../tmp/tx.draft \
    --change-address ${base_address} \
    --tx-in ${payee_tx_in} \
    --certificate ../data/staking/deleg.cert \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
FEE=${FEE[1]}
echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ../wallets/delegator-wallet/payment.skey \
    --signing-key-file ../wallets/delegator-wallet/stake.skey \
    --tx-body-file ../tmp/tx.draft \
    --out-file ../tmp/tx.signed \
    ${network}
#    
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file ../tmp/tx.signed
