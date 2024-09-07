#!/usr/bin/env bash
set -e
export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
network=$(cat ../data/network.sh)

drepHash=$(cat ../../hashes/drep.hash)

# Ensure the script receives exactly three arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <url> <hash>"
    exit 1
fi

# Validate the first argument (string)
if [[ ! "$1" =~ ^[a-zA-Z0-9:/.]+$ ]]; then
    echo "Error: First argument must be a string."
    exit 1
fi

if [[ ! "$2" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "Error: First argument must be a string."
    exit 1
fi

url="$1"
hash="$2"

${cli} conway governance drep update-certificate \
--drep-script-hash ${drepHash} \
--drep-metadata-url "${url}" \
--drep-metadata-hash "${hash}" \
--out-file ../../certs/update.cert

mkdir -p ../tmp
${cli} conway query protocol-parameters ${network} --out-file ../tmp/protocol.json

# who will pay for the tx
hot_address=$(cat ../wallets/hot-wallet/payment.addr)
hot_pkh=$(${cli} conway address key-hash --payment-verification-key-file ../wallets/hot-wallet/payment.vkey)

# collateral for stake contract
collat_address=$(cat ../wallets/collat-wallet/payment.addr)
collat_pkh=$(${cli} conway address key-hash --payment-verification-key-file ../wallets/collat-wallet/payment.vkey)

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

# collat info
echo -e "\033[0;36m Gathering Collateral UTxO Information  \033[0m"
${cli} conway query utxo \
    ${network} \
    --address ${collat_address} \
    --out-file ../tmp/collat_utxo.json

TXNS=$(jq length ../tmp/collat_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${collat_address} \033[0m \n";
   exit;
fi
collat_utxo=$(jq -r 'keys[0]' ../tmp/collat_utxo.json)

script_ref_utxo=$(${cli} conway transaction txid --tx-file ../tmp/drep-reference-utxo.signed )

echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} conway transaction build \
    --out-file ../tmp/tx.draft \
    --change-address ${hot_address} \
    --tx-in-collateral="${collat_utxo}" \
    --tx-in ${hot_tx_in} \
    --certificate ../../certs/update.cert \
    --certificate-tx-in-reference="${script_ref_utxo}#1" \
    --certificate-plutus-script-v3 \
    --certificate-reference-tx-in-redeemer-file ../data/drep/update-redeemer.json \
    --required-signer-hash ${collat_pkh} \
    --required-signer-hash ${hot_pkh} \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
echo -e "\033[1;32m Fee: \033[0m" $FEE

echo "Updating ${drepHash} with data from ${url} and hash: ${hash}"
echo "Press Enter to continue, or any other key to exit."
read -rsn1 input

if [[ "$input" == "" ]]; then
    echo "Updating..."
else
    echo "Exiting."
    exit 0;
fi
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} conway transaction sign \
    --signing-key-file ../wallets/hot-wallet/payment.skey \
    --signing-key-file ../wallets/collat-wallet/payment.skey \
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