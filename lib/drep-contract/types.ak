use aiken/crypto.{ScriptHash}
use cardano/assets.{Lovelace}
use cardano/governance.{GovernanceActionId, Vote}

pub type Redeemer {
  Register(ScriptHash, Lovelace)
  UnRegister(ScriptHash, Lovelace)
  Update(ScriptHash)
  CastVote(GovernanceActionId, Vote)
  Propose
}
