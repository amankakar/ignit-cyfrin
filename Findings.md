# in case of price oracle update why the old priceAge is being used
# in case of swap the difference is as follows :
Logs(2587322779489373945262) : slippage calcualtion set this amount to minOut
Logs(2614929191496792705208) : the actula amount the contract receive after swap so it will create the arbitrage apportunity
1. In case of 1% slippage: 
Logs:
  amountsOut From router 525329355907312070588839 : 197.02
  amountsOut 526513300393457777978201 : 197.5 Here it will fail 

2. in case of 2% slippage :
Logs:
  amountsOut From router 526155459560601710084992 : 197.02
  amountsOut 523518697712638222814113 : 196.2
issue No 2 : 
  Zeeve will transfer Qi token worth of 196.2 AVAX to ignite and the ignite contract will check for the 201 AVAX 196.2 AVAX will went through instead of 201 AVAX and after 9/10 the expectedAmount will be 181.1 AVAX  
  in ignite calculation :  
  user provided : 523518697712638222814113
  Expected Amount :  537361931967102793145706 // in case 201 AVAX
  Expected Amount after converion : 483625738770392513831135 // After 9/10 conversion

  elgiable fro rewards :  523518697712638222814113 / 201; // fee calcualtion 201/201 => 1 , 196/201  => 0.97 / 0.900 Fee m jaingy mugar us ki fee hai 1 AVAX 


issue No 3:
## in case of staking amount we need 200 = 1 AVAX for fee of ignite but the zeeve only deals with stakeAmount 


# The slippage logic in `swapForQI` is flawed
## Summary
The staking contract handles slippage in a very strict manner; it will either revert due to insufficient tokens received or create arbitrage opportunities by not using BPS-based accounting for slippage. The contract only supports slippage values of 1%, 2%, 3%, 4%, etc.  

## Vulnerability Details
At the time of writing this report, the staking contract reverts when a user calls `stakeWithAVAX` with the slippage set to `1%` during initialization, resulting in the error `[Revert] revert: JoeRouter: INSUFFICIENT_OUTPUT_AMOUNT`. As a result, the admin will increase the slippage to `2%`. This adjustment creates an arbitrage opportunity since the swap transaction also includes a deadline set to `block.timestamp`, leading to potential asset loss for both the end user and Benqi. (The impact on Benqi due to this arbitrage is discussed in a separate finding.)  
Let's analyze the values received in the two cases:

**Case 1: Slippage set to 1%**  
```solidity
  Staking AVAX amount: 200 AVAX  
  AmountsOut from router (QI Amount joeRouter.getAmountOut()): 522181912801708034303330  
  AmountsOut applying 1% slippage (QI Amount): 523371390515414735694282  

The above will revert due to `INSUFFICIENT_OUTPUT_AMOUNT`.

**Case 2: Slippage set to 2%**  
```solidity
  Staking AVAX amount: 200 AVAX  
  AmountsOut from router (QI Amount joeRouter.getAmountOut()): 522186764231334533888113  
  AmountsOut expected after applying 2% slippage: 519623805819669076396933  
  Arbitrage opportunity: 522186764231334533888113 - 519623805819669076396933  
                      => 2562958411665457491180 (2562e18 QI tokens)  
  In USD terms, the arbitrage value amounts to approximately $32 per swap.
```

For POC I will share my github repo link [github]():

```solidity
    function test_arbitrage() external {
        uint256 stakeAmount = _getRegistrationFee(86400 * 7 * 12);
        stakeAmount = stakingInstance.avaxStakeAmount();
        uint256 avaxFee = stakingInstance.calculateHostingFee(86400 * 7 * 12);

        // cache user AVAX balance than we will find out the AVAX amount used in registeration
        uint256 initialBalance = address(bob).balance;
        uint256 msgValue = stakeAmount + avaxFee;
        address[] memory path = new address[](2);
        path[0] = ghost_joeRouter.WAVAX();
        path[1] = address(qiTokenAddress);

        uint256[] memory amountsOut = ghost_joeRouter.getAmountsOut(
            stakeAmount,
            path
        );
        uint256 expectedQiAmount = stakingInstance.convertTokenToQi(
            AVAX,
            stakeAmount
        );
        uint256 slippageFactor = 100 - stakingInstance.slippage(); // Convert slippage percentage to factor
        uint256 amountOutMin = (expectedQiAmount * slippageFactor) / 100; // Apply slippage
        console.log(
            "amountsOut From router",
            amountsOut[amountsOut.length - 1]
        );
        console.log("amountsOut", amountOutMin);
        vm.prank(bob);
        stakingInstance.stakeWithAVAX{value: msgValue}(86400 * 7 * 12);
    }
```
Test Command : `forge test --mt test_arbitrage -vvv`

you only need to change following code values to test both cases:
```solidityzeeve/src/staking.sol:228
2025-01-benqi/zeeve/src/staking.sol:218
218:         slippage = 2; // 1% slippage make it 1 will revert , 2 will create arbitrage
```

## Impact
When the slippage is set too low, the transaction fails with an `INSUFFICIENT_OUTPUT_AMOUNT` error. On the other hand, increasing the slippage to avoid reverts leads to arbitrage opportunities, allowing bots to exploit the difference and profit at the expense of the protocol and users assets.

## Tools Used
Foundry

## Recommendations
To prevent large arbitrage opportunities, it's recommended to introduce **decimals basis points (BPS)** to the slippage mechanism. This will allow for more granular control over slippage and help reduce the risk of creating significant arbitrage opportunities while still ensuring that the transaction succeeds.

```diff
diff --git a/zeeve/src/staking.sol b/zeeve/src/staking.sol
index 5d6b468..0fc9a5b 100644
--- a/zeeve/src/staking.sol
+++ b/zeeve/src/staking.sol
@@ -215,9 +215,9 @@ contract StakingContract is
         avaxStakeAmount = _initialStakingAmount;
         hostingFeeAvax = _initialHostingFee;
         joeRouter = IJoeRouter02(_joeRouter);
-        slippage = 1; // 1% slippage
+        slippage = 10; // 1% slippage
         minSlippage = 0; // Min slippage
-        maxSlippage = 5; // Max slippage
+        maxSlippage = 50; // Max slippage
         refundPeriod = 5 days;

@@ -908,8 +908,8 @@ contract StakingContract is
         }
 
         // Get the best price quote
-        uint256 slippageFactor = 100 - slippage; // Convert slippage percentage to factor
-        uint256 amountOutMin = (expectedQiAmount * slippageFactor) / 100; // Apply slippage
+        uint256 slippageFactor = 1000 - slippage; // Convert slippage percentage to factor
+        uint256 amountOutMin = (expectedQiAmount * slippageFactor) / 1000; // Apply slippage
         emit Logs(amountOutMin);
         // emit Logs(expectedQiAmount);

```

================================================================================================================
# The Logic around swapping with joeRouter is not correct

## Summary
The `swapForQi` function directly enforces the slippage factor set by the Zeeve admin, regardless of potential arbitrage opportunities.

## Vulnerability Details
When a user calls `stakeWithAvax` or `stakeWithERC20`, the staking contract performs a swap from `AVAX` to `QI` or `ERC20` to `QI` tokens. In this particular case, the focus will be on the `AVAX/QI` pair. The amount of `QI` tokens is calculated on-chain using the slippage factor defined by the Zeeve admin.  
```solidity
2025-01-benqi/zeeve/src/staking.sol:910
910:         // Get the best price quote
911:         uint256 slippageFactor = 100 - slippage; // Convert slippage percentage to factor
912:         uint256 amountOutMin = (expectedQiAmount * slippageFactor) / 100; // Apply slippage
913: 
914:         uint256[] memory amountOutReal;
915:         uint256 deadline = block.timestamp;
```
The user can easily be forced by any bot to receive the `amountOutMin`, regardless of the current state of the `AVAX/QI` pool. The following attack vector can be exploited by any arbitrage bot:

1. The staking contract submits a swap transaction with `1%` slippage. Let's assume the `amountOutMin = 519623805819669076396933 QI` and `AVAX = 200e18`.
2. However, the actual `amountOut` from the router's `getAmountsOut` function is `522186764231334533888113 QI`.
3. The bot manipulates the pool's state, forcing the staking contract to receive only `519623805819669076396933 QI` tokens.
4. The bot places a transaction immediately after the staking contract's swap and profits `2562e18 QI` tokens.

The case presented above creates an arbitrage opportunity in USD value of approximately `$37`, based on the current market price. This value can accumulate with each subsequent swap.  

## Impact
Each swap performed by the staking contract is vulnerable to arbitrage opportunities.  

## Tools Used
Manual Review

## Recommendations
Calculate the `minAmountOut` off-chain and provide it as a parameter when calling `stakeWithAVAX` or `stakeWithERC20`.  

==================================================================================================================
# In case of price oracle update why the old priceAge is being used
## Summary
In the `updatePriceFeed` function, the staleness check uses the timeout of the current oracle for the new oracle. This approach can lead to inconsistencies and potential issues, as the timeout period for the new oracle may differ from the current one, causing incorrect staleness checks or does not allow to add new oracle .


## Vulnerability Details
The staking contract imposes a **staleness check** when adding or setting an oracle within the contract. 

```solidity
2025-01-benqi/zeeve/src/staking.sol:964
964:     function _validateAndSetPriceFeed(
965:         address token,
966:         address priceFeedAddress,
967:         uint256 maxPriceAge
968:     ) internal {
969:         require(token != address(0), "Invalid token address");
970:         require(priceFeedAddress != address(0), "Invalid price feed address");
971:         require(maxPriceAge > 0, "Invalid max price age");
972:         AggregatorV3Interface priceFeed = AggregatorV3Interface(
973:             priceFeedAddress
974:         );
975:         (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
976:         require(price > 0, "Invalid price");
977:         require(block.timestamp - updatedAt <= maxPriceAge, "Stale price");
978:         priceFeeds[token] = priceFeed;
979:         maxPriceAges[token] = maxPriceAge;
980:     }
```
The staking contract allows the admin to change the token's oracle price feed. However, it uses the current staleness value, stored in the `maxPriceAge` mapping, when adding a new oracle.

```solidity
2025-01-benqi/zeeve/src/staking.sol:629
629:     function updatePriceFeed(
630:         address token,
631:         address newPriceFeed
632:     ) external onlyRole(BENQI_ADMIN_ROLE) {
633:         require(acceptedTokens.contains(token), "Token not accepted"); // Check if the token is accepted
634:         address oldPriceFeed = address(priceFeeds[token]);
635:         _validateAndSetPriceFeed(token, newPriceFeed, maxPriceAges[token]); // @audit : why using old maxPiceAge here ??
636:         emit PriceFeedUpdated(token, oldPriceFeed, newPriceFeed);
637:     }
```

The issue arises because Chainlink oracles can have different staleness times for the current and new oracles. This discrepancy could either cause the system to mistakenly treat the staleness price as valid or, conversely, lead to a revert even when the price is correct.


## Impact
Due to the difference in staleness times, either the oracle cannot be added, or the system will incorrectly treat stale prices as fresh prices.

## Tools Used
Manual Review
## Recommendations
Also the take maxPriceAge as argument as it is being done in ignite contract.
