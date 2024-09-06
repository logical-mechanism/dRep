#!/usr/bin/env bash
set -e

# create directories if dont exist
mkdir -p contracts
mkdir -p hashes
mkdir -p certs

# remove old files
rm contracts/* || true
rm hashes/* || true
rm certs/* || true
rm -fr build/ || true

# build out the entire script
echo -e "\033[1;34m Building Contracts \033[0m"

# remove all traces
# aiken build --trace-level silent --filter-traces user-defined

# keep the traces
aiken build --trace-level verbose --filter-traces all

hot_key=$(jq -r '.hotKey' config.json)
hot_key_cbor=$(python3 -c "import cbor2;hex_string='${hot_key}';data = bytes.fromhex(hex_string);encoded = cbor2.dumps(data);print(encoded.hex())")

echo -e "\033[1;33m dRep Contract \033[0m"
aiken blueprint apply -o plutus.json -v drep.contract.publish "${hot_key_cbor}"
aiken blueprint convert -v drep.contract.publish > contracts/drep_contract.plutus
cardano-cli conway transaction policyid --script-file contracts/drep_contract.plutus > hashes/drep.hash

cardano-cli conway governance drep registration-certificate \
--drep-script-hash $(cat hashes/drep.hash) \
--key-reg-deposit-amt $(cat ./scripts/tmp/protocol.json | jq -r '.dRepDeposit') \
--out-file certs/register.cert

cardano-cli conway governance drep retirement-certificate \
--drep-script-hash $(cat hashes/drep.hash) \
--deposit-amt $(cat ./scripts/tmp/protocol.json | jq -r '.dRepDeposit') \
--out-file certs/unregister.cert

# this is broken for scripts right now
# change 0 tag to 1 in cbor
cardano-cli conway governance drep update-certificate \
--drep-key-hash $(cat hashes/drep.hash) \
--drep-metadata-url https://www.logicalmechanism.io/drepTestnet \
--drep-metadata-hash 55c4ea20e133878ef8c80ddbf3f73adbe3220963a2874f8757d435d60126db41 \
--out-file certs/update.cert

echo -e "\033[1;33m Updating Drep Redeemer \033[0m"
drepHash=$(cat ./hashes/drep.hash)
jq \
--arg drepHash "$drepHash" \
'.fields[0].bytes=$drepHash' \
./scripts/data/drep/register-redeemer.json | sponge ./scripts/data/drep/register-redeemer.json

drepHash=$(cat ./hashes/drep.hash)
jq \
--arg drepHash "$drepHash" \
'.fields[0].bytes=$drepHash' \
./scripts/data/drep/unregister-redeemer.json | sponge ./scripts/data/drep/unregister-redeemer.json

drepHash=$(cat ./hashes/drep.hash)
jq \
--arg drepHash "$drepHash" \
'.fields[0].bytes=$drepHash' \
./scripts/data/drep/update-redeemer.json | sponge ./scripts/data/drep/update-redeemer.json

drepHash=$(cat ./hashes/drep.hash)
jq \
--arg drepHash "$drepHash" \
'.fields[1].bytes=$drepHash' \
./scripts/data/drep/delegate-redeemer.json | sponge ./scripts/data/drep/delegate-redeemer.json

# end of build
echo -e "\033[1;32m Building Complete! \033[0m"