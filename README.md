# Logical Mechanism dRep Contract

A smart contract dRep for Logical Mechanism LLC.

The goal of this contract is a basic dRep. It can register, unregister, update, and vote. It does not provide stake thus it can not propose. It is controlled by a single controller key known at compile time. It is simple but that is the point. It serves as a quick method to vote and as a demostrative tool for other developers wishing to know how to build dRep contracts.

## Setup

The contract requires Aiken 1.1.0, stdlib 2.0.0, and cardano-cli 9.4.0.0+ (older version did not allow script dReps to update). The build and happy path scripts require jq, sponge, and python3. Start by create the required wallets for the happy path in the `scripts` folder.

```bash
./create_wallet.sh wallets/collat-wallet
./create_wallet.sh wallets/hot-wallet
./create_wallet.sh wallets/reference-wallet
```

The collat wallet needs 5 ADA, the reference wallet needs 10 ADA, and the hot wallet needs 500 ADA for the dRep deposit and another 100 ADA for spending. An optional `delegator-wallet` can be made that is a full staking wallet, use the `create-wallet.sh` script along with the cardano-cli to generate the appropate stake keys.

Update the `config.yaml` file in the parent directory with the hot wallet public key hash. It will act as the controller for the dRep.

```json
{
  "__comment1__": "The Drep hot key",
  "hotKey": ""
}
```

Use the `complete_build.sh` script to compile the dRep contract. It will auto-populate the cert files and data files for the happy path. At this point, the dRep is ready for the happy path.

## Happy Path

Run `00_createScriptReferences.sh` to create the script reference UTxO for the smart contract. It will store the UTxO at the reference wallet address. Enter the `drep` folder and run `01_registerDrep.sh`.

The dRep can now be delegated by other users.


### Metadata

A drep can have metadata associated with it and is suggested that it does.

- TODO

### Voting

- TODO