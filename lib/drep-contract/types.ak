use aiken/crypto.{ScriptHash}
use cardano/assets.{Lovelace}

pub type Redeemer {
  Register(ScriptHash, Lovelace)
  UnRegister(ScriptHash, Lovelace)
  Update(ScriptHash)
  CastVote
}
