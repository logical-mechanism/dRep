# Logical Mechanism dRep Contract

A smart contract dRep for Logical Mechanism LLC.

The goal of this contract is a basic dRep. It can register, unregister, update, and vote. It does not provide stake thus it can not propose. It is controlled by a single controller key known at compile time. It is simple but that is the point. It serves as a quick method to vote and as a demostrative tool for other developers wishing to know how to build dRep contracts.

## Setup

The contract requires Aiken 1.1.0, stdlib 2.0.0, and cardano-cli 9.4.0.0+ (older version did not allow script dReps to update). The build and happy path scripts require jq, sponge, and python3. The path to the cardano-cli needs to be defined in `scripts/data/path_to_cli.sh`, the path to the cardano-node socket needs to be defined in `scripts/data/path_to_socket.sh`, and the network needs to be defined in `scripts/data/network.sh`. A fully-synced cardano-node is required for the happy path.

### Wallet Generation

Start by creating the required wallets for the happy path in the `scripts` folder.

```bash
./create_wallet.sh wallets/collat-wallet
./create_wallet.sh wallets/hot-wallet
./create_wallet.sh wallets/reference-wallet
```

The collat wallet needs 5 ADA, the reference wallet needs 10 ADA, and the hot wallet needs 500 ADA for the dRep deposit and another 100 ADA for spending. An optional `delegator-wallet` can be made that is a full staking wallet, use the `create-wallet.sh` script along with the cardano-cli to generate the appropate stake keys.

Update the `config.yaml` file in the parent directory with the `hot-wallet` public key hash from the `payment.hash` file. This wallet will act as the controller for the dRep so keep these keys secure.

```json
{
  "__comment1__": "The dRep hot key",
  "hotKey": ""
}
```

Use the `complete_build.sh` script to compile the dRep contract. It will auto-populate the certificate folder and required data files. At this point, the dRep is ready for the happy path.

## Happy Path

Run `00_createScriptReferences.sh` to create the script reference UTxO for the smart contract. It will store the UTxO at the reference wallet address. Enter the `drep` folder and run `01_registerDrep.sh`. When the transaction lands on-chain the dRep is officially registered.

The dRep can now be delegated by other users.

### Metadata

A dRep can have metadata and it is suggested that it does. An example metadata file is located at `scripts/data/drep/drep.metadata.json`. It needs to be hosted on-line, github will work just use the raw view url. Updating the drep requires a blake2b-256 hash to be calculated of the metadata file. Use `cardano-cli conway governance drep metadata-hash --drep-metadata-file FILE` to get the hash.

The dRep can be updated by using

```bash
./03_updateDrep.sh ${metadataURL} ${metadataHash}
```

This will use the hot key to pay for the tx and will sign for the metadata update.

### Voting

The dRep can vote by using

```bash
./04_voteGovernance.sh ${txId} ${govActionIx} ${voteOption}
```

where `voteOption` is either yes, no, or abstain. This will use the hot key to pay for the tx and will sign for the governance vote.

### Governance Queryies

The governance queries are basic but get the point across. In the `gov` folder run `query_all_gov_actions.sh` to view all current governance actions. There should be URL links for additional information. To vote on a governance action with the dRep locate the txId and govActionIx.

```json
"actionId": {
  "govActionIx": 0,
  "txId": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
},
```

This information is what is required to run the `./04_voteGovernance.sh ${txId} ${govActionIx} ${voteOption}` script inside the `drep` folder. To query the specific governance action use `./query_specific_gov_action.sh  ${txId} ${govActionIx}`.

## Contact

For any questions or feedback, please contact the project maintainer at `support@logicalmechanism.io`.