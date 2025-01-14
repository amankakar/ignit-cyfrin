## Summary
•   Allows users to register nodes for validation using different payment/staking methods (e.g., AVAX, QI and supported ERC-20 tokens).
•	Handles deposits, rewards, slashing, and withdrawal of tokens.
•	Supports flexible validation durations and subsidized validator staking.
## Entry Point
- **registerWithStake:** 
Register a new node for validation and lock up QI and AVAX
- **registerWithAvaxFee:** 
Register a node by paying a non-refundable fee in AVAX
- **registerWithErc20Fee:** 
Register a node by paying a non-refundable fee in a supported ERC-20 token
- **registerWithPrevalidatedQiStake:** 
Register a new node with a pre validated QI deposit amount. and become Eligible for QI rewords.
- **registerWithoutCollateral:** 
Register a new node for validation without locking up tokens. Non-tokenised registrations do not count towards the subsidisation cap.

## Exit Point 
1. **releaseLockedTokens:** Called by admin after the validation period has expired and the tokens become redeemable by the original staker and  transfer fees and slashed amount to  `FEE_RECIPIENT` and `SLASHED_TOKEN_RECIPIENT` respectively. 
2. **redeemAfterExpiry:** called by user after the validation period has expired and the staker wants to redeem their deposited tokens and potential rewards. Deletes registration entry.
3. **withdraw:** Called by admin to withdraw AVAX from the contract. ensures `address(this).balance >= minimumContractBalance`

## internal function :
1. _register : create registration entry. called in side `_registerWithChecks` and `registerWithoutCollateral`.
2. _registerWithChecks : ensures subsidisation cap validation and the validation duration limits.
3. _initialisePriceFeeds : called at the time of contract initialization
4. _deleteRegistration : deletes registration entry. called at the time of `redeemAfterExpiry`
5. _getRegistrationFee : Get the registration fee in AVAX for a given validation duration. 

## External Interaction 
- chainlinkOracle.latestRoundData()
- ValidatorRewarder.claimRewards()

## Attack Vector
what if the qi price surpass avax price in `registerWithStake`
## Main invariants
1. The contract `minimumContractBalance` must have enough funds remaining after the admin withdrawal.  `address(this).balance >= minimumContractBalance`
2. Subsidization cap should always holds. `totalSubsidisedAmount <= maximumSubsidisationAmount`


## Function invariants 
1. after registration/staking process the contract must have the staking asset balance
2. after the  releaseLockedTokens the `FEE_RECIPIENT` and `SLASHED_TOKEN_RECIPIENT` should receieve the fees.  
	•	Reward amounts must be correctly calculated and distributed only to eligible validators.
	•	Ensure slashing percentages do not exceed 100% (qiSlashPercentage <= 10_000).
3. in `registerWithStake` qiPrice > 0 && avaxPrice > qiPrice
4. 	Functions that depend on the contract’s active state (e.g., registration, redemption) must enforce the whenNotPaused modifier.
	•	Only users with ROLE_PAUSE or ROLE_UNPAUSE can alter the paused state.
## Conclusion 
We have a very good understanding of this contract
