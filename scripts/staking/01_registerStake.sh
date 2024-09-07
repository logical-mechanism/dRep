#!/usr/bin/env bash
set -e

## TESTING ONLY

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

# stake address deposit
stakeAddressDeposit=$(cat ../tmp/protocol.json | jq -r '.stakeAddressDeposit')
${cli} conway stake-address registration-certificate --stake-verification-key-file ${skh} --key-reg-deposit-amt ${stakeAddressDeposit} --out-file ../data/staking/stake.cert

echo stakeAddressDeposit : $stakeAddressDeposit
#
# exit
#
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

echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} conway transaction build \
    --out-file ../tmp/tx.draft \
    --change-address ${base_address} \
    --tx-in ${payee_tx_in} \
    --certificate ../data/staking/stake.cert \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"

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
