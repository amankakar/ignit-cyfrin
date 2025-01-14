## Summary
The  main Working of this contract is that user will either deposit AVAX or whitelisted ERC20 token, the contract than convert that token to QI after deducting the Hosting Fee. After this the admin could either refund the deposit assets or register the node for staker. 
In case of registering the node the contract calls ignite contract to push the stacker data there. 

## Entry Point

- stakeWithAVAX:
    This function allow the stacker to stake the avax for QI token in a valid duration provided by stacker.This function assert the required amount for stake and also refund the access amount , perform the swap form avax to QI token.  create User staking record here the status is set to `status = StakingStatus.Provisioning`.

- stakeWithERC20:
    This function allow the stackers to stake via accepted token. this function first convert the stake amount and fee to the given token and than subtract the fee amount f token is QI token other wise swap the token in Qi token and store the entry.

- registerNode:
    After calling either of the above 2 function . This function will be called by ZEEVE Admin and a node to validator list . this function will either charge the Fee in AVAX or QI token to pay the Fee to ZEEVE. This also set the `status = StakingStatus.Provisioned` at the end. this function takes BLSProof and check its lenght `blsProofOfPossession==14` This function will interact with ignite Contract `registerWithPrevalidatedQiStake` to register the node. 



- ### Config Function
    - AddToken : 
        Called via `BENQI_ADMIN_ROLE` to add token to accepted list. it also configure the priceFeed with maxPriceAge.
    - removeToken : 
        Called via `BENQI_ADMIN_ROLE` to remove token from accepted list.
    - setMinSlippage : 
        Called via `BENQI_ADMIN_ROLE` to set the new min splippage one issue spoted that we need to remove `=` sign
    - setMaxSlippage : 
        Called via `BENQI_ADMIN_ROLE` to set the new max slippage. check again the current slippage
    - setSlippage : 
        Called via `BENQI_ADMIN_ROLE` to set new slippage and also bound it around min/max slipage.
    - updateStakingFee: 
        Called via `BENQI_ADMIN_ROLE` to set the Staking Fee Amount , I think this will be the amount which user will stake to participate in validation.
    - updateHostingFee: 
        Called via `BENQI_ADMIN_ROLE` to set the Hosting Fee , this amount will be charged when we deposit staking token.
    - updatePriceFeed: 
        Called via `BENQI_ADMIN_ROLE` to update the price feed of token , However it uses the old `maxPriceAge` i think it is problamtic.
    - setIntermediaryToken: 
        Called via `BENQI_ADMIN_ROLE` to set the intermediary token the purpose of this function is to handle the case where no direct swapping from token to QI token is possible.
    - setRefundPeriod: 
        Called via `BENQI_ADMIN_ROLE` To set the refund time the purpose of this function is to set the time duration which the amount of user will be refunded
    - grantAdminRole: 
        It could be called by `BENQI_SUPER_ADMIN_ROLE` or `ZEEVE_SUPER_ADMIN_ROLE` to grand admin role to given account. it will revert if the given role is not ADMIN Role.
    - revokeAdminRole: 
        It could be called by `BENQI_SUPER_ADMIN_ROLE` or `ZEEVE_SUPER_ADMIN_ROLE` to revoke admin role of given account. it will revert if the given role is not ADMIN Role.
    - updateAdminRole: 
        It could be called by `BENQI_SUPER_ADMIN_ROLE` or `ZEEVE_SUPER_ADMIN_ROLE` to revoke admin role of given account oldAdmin  and assign ADMIN role to newAdmin. it will revert if the given role is not ADMIN Role.



## Exit Point 
- refundStakedAmount :
    This function will be called by `BENQI_ADMIN_ROLE`, which will refund the staking amount which user has stacked and in status of `Provisioning` which means there is no node registration done for it now.
    It pay back the stake amount in QI token and hosting Fee in AVAX. update the status to `Refunded`.

## internal function :
- convertAvaxToToken:
    Helper function which will help to convert the  avax to given token amount.
- _validateAndSetPriceFeed : 
    Utility function which will set the new priceFeed for a given token , it also validate that the price is not stale i think it is not good apparoch  
- swapForQI : 
    Utility function which will help to swap token on joe router, the function will either use Intermediary swap flow or use direct swap flow. it will perform the    slippage calculation and either call `swapExactAVAXForTokens` or `swapExactTokensForTokens`.
- _getPriceInUSD: 
    This function will fetch the USD price of given token from token priceFee and also it apply the required check. this function return the used price in 18 decimals.
- convertTokenToQi: 
    Helper Function which we help to convert the given token in QI token. The final reposne will represent the the QI token amount of given token.


## External Interaction 
- registerNode
    After calling either of the above 2 function . This function will be called by ZEEVE Admin and a node to validator list . this function will either charge the Fee in AVAX or QI token to pay the Fee to ZEEVE. This also set the `status = StakingStatus.Provisioned` at the end. this function takes BLSProof and check its lenght `blsProofOfPossession==14` This function will interact with ignite Contract `registerWithPrevalidatedQiStake` to register the node. 
- it also interact with chainlink price oracle for pricing and with joe router for swap

## Attack Vector
- Check the BLSProof Length must be 14 in every case? function :`registerNode`. 
- Check the swap function is there any arbitrage possible and also we did not check the return QI amount from swap?
- check in case of refund call which token will be refund , is it will be the same token or only avax or QI token will be send

## Main invariants
1. total QI token  in contract must be equal to total deposit of all token in USD. as we convert the tokens to QI after depositERC20/depositAVAX.


## Function invariants 
1. After deposit token check the balance of contract should be >= the deposit amount , or declare a ghost variable which will track the balance after each deposit. ans check with the total balance of staking contract.


## Flow Diagram :

<iframe style="border: 1px solid rgba(207, 198, 198, 0.1);" width="800" height="450" src="https://embed.figma.com/board/EjfG2ZVDpPz9JcfNXuzU3L/Swap-1?node-id=492-1509&embed-host=share" allowfullscreen></iframe>

## Conclusion 
We have a very good understanding of this contract
