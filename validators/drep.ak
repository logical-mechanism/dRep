use aiken/collection/pairs
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script, VerificationKey}
use cardano/certificate.{
  Certificate, RegisterDelegateRepresentative, UnregisterDelegateRepresentative,
  UpdateDelegateRepresentative,
}
use cardano/governance.{ProposalProcedure, Voter}
use cardano/transaction.{Transaction}
use cardano/tx
use drep_contract/types.{
  CastVote, Propose, Redeemer, Register, UnRegister, Update,
}

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
        _ -> fail @"Bad Drep Redeemer"
      }
    and {
      // The only cert is for new delegation
      (certificate == new_certificate)?,
      // the controller must sign it
      tx.verify_signature(extra_signatories, controller)?,
    }
  }

  vote(redeemer: Redeemer, voter: Voter, transaction: Transaction) {
    let Transaction { extra_signatories, votes, .. } = transaction
    expect CastVote(gov_id, my_vote) = redeemer
    expect Some(gov_vote) = pairs.get_first(votes, voter)
    expect Some(the_vote) = pairs.get_first(gov_vote, gov_id)
    and {
      // The vote must match my vote
      (the_vote == my_vote)?,
      // the controller must sign it
      tx.verify_signature(extra_signatories, controller)?,
    }
  }

  propose(
    redeemer: Redeemer,
    proposal_procedure: ProposalProcedure,
    transaction: Transaction,
  ) {
    let Transaction { extra_signatories, .. } = transaction
    expect Propose = redeemer
    and {
      // return address needs to the controller
      proposal_procedure.return_address == VerificationKey(controller),
      // the controller must sign it
      tx.verify_signature(extra_signatories, controller)?,
    }
  }

  else(_) {
    fail
  }
}
