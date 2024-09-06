use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script}
use cardano/certificate.{
  Certificate, RegisterDelegateRepresentative, UnregisterDelegateRepresentative,
  UpdateDelegateRepresentative,
}
use cardano/governance.{Voter}
use cardano/transaction.{Transaction}
use cardano/tx
use drep_contract/types.{CastVote, Redeemer, Register, UnRegister, Update}

validator contract(controller: VerificationKeyHash) {
  publish(
    redeemer: Redeemer,
    certificate: Certificate,
    transaction: Transaction,
  ) {
    let Transaction { extra_signatories, .. } = transaction
    let new_certificate: Certificate =
      when redeemer is {
        Register(script_hash, lovelace) ->
          RegisterDelegateRepresentative {
            delegate_representative: Script(script_hash),
            deposit: lovelace,
          }
        UnRegister(script_hash, lovelace) ->
          UnregisterDelegateRepresentative {
            delegate_representative: Script(script_hash),
            refund: lovelace,
          }
        Update(script_hash) ->
          UpdateDelegateRepresentative {
            delegate_representative: Script(script_hash),
          }
        _ -> fail @"Bad dRep Redeemer"
      }
    and {
      // The only cert is for new delegation
      (certificate == new_certificate)?,
      // the controller must sign it
      tx.verify_signature(extra_signatories, controller)?,
    }
  }

  vote(redeemer: Redeemer, _voter: Voter, transaction: Transaction) {
    let Transaction { extra_signatories, .. } = transaction
    expect CastVote = redeemer
    tx.verify_signature(extra_signatories, controller)
  }

  else(_) {
    fail
  }
}
