## [M-1] Missing 1 AVAX in amountStaked for `registerWithPrevalidatedQiStake`

## Summary
Lets assume `hostingFee` to be `1.4 AVAX`. When a user calls `stakeWithAVAX` function with `200 + 1.4 AVAX`, the contract converts `200 AVAX` to `QI` (recorded in amountStaked) and `1.4 AVAX` as a separate hosting fee (recorded in hostingFeePaid). However, in `registerNode` function, the contract then fetches `record.amountStaked` and passes it to `igniteContract.registerWithPrevalidatedQiStake`. That function in the Ignite contract expects `200 AVAX + 1 AVAX` worth of QI (i.e., 201 AVAX worth of QI), but the zeeve staking contract only provides `200 AVAX` worth of `QI`. This discrepancy can cause the function to fail its requirement checks.

## Vulnerability Details
In `stakeWithAVAX` function, the user might send, for example, `200 + 1.4 AVAX`. The contract logic calculates and stores only the `QI` representing `200 AVAX` in `record.amountStaked`:  

```solidity
/ignit-cyfrin/zeeve/src/staking.sol:471
471:         uint256 hostingFee = calculateHostingFee(duration);
472:         require(
473:             msg.value >= avaxStakeAmount + hostingFee,
474:             "Insufficient AVAX sent"
475:         );
476: 
477:         // Calculate the total required amount
478:         uint256 totalRequired = avaxStakeAmount + hostingFee;
...
492:         UserStakeRecords storage userRecords = stakeRecords[msg.sender];
493:         uint256 index = userRecords.stakeCount;
494:         // Record the staking details
495:         userRecords.records[index] = StakeRecord({
496:             amountStaked: stakingAmountInQi,
497:             hostingFeePaid: hostingFee,
...
502:         });

```
This leaves 1 AVAX (the additional fee expected by Ignite) unaccounted for in the `amountStaked`.

Later, `registerNode` function is called and it retrieves:

```solidity
/ignit-cyfrin/zeeve/src/staking.sol:422
422: 
423:         uint256 qiAmount = record.amountStaked; // 200 avax worth of QI
424: 

```

This `qiAmount` is then used:

```solidity
/ignit-cyfrin/zeeve/src/staking.sol:442
442:         // Call the external function
443:         igniteContract.registerWithPrevalidatedQiStake(
444:             user,
445:             nodeId,
446:             blsProofOfPossession,
447:             record.duration,
448:             qiAmount
449:         );


```

But `registerWithPrevalidatedQiStake` function expects an additional 1 AVAX (beyond the 200 AVAX) as part of the QI amount:

```solidity
/ignit-cyfrin/ignite/src/Ignite.sol:386
386:         // 200 AVAX + 1 AVAX fee
387:         uint expectedQiAmount = uint(avaxPrice) * 201e18 / uint(qiPrice); // qi amount
388: 
389:         require(qiAmount >= expectedQiAmount * 9 / 10); 
390: 
391:         qi.safeTransferFrom(msg.sender, address(this), qiAmount);
392: 

```


Because the staking contract only provides QI for 200 AVAX, the requirement (201 AVAX worth of QI) does not met, causing a revert.

## Impact
This discrepancy can lead to Revert because the Ignite contract strictly enforces the requirement for 201 AVAX worth of QI, leading the call to `registerWithPrevalidatedQiStake` revert.

## Tools Used
Manual Review 

## Recommendations
Ensure that the staking contract’s record.amountStaked includes 200 AVAX + 1 AVAX worth of QI, or store it in a separate field and combine it when calling `registerWithPrevalidatedQiStake`.






## [M-2] Overly Lenient `qiAmount` Requirement in `registerWithPrevalidatedQiStake`

## Summary
In the Ignite.sol contract, the registerWithPrevalidatedQiStake function requires only 90% of the “expected” QI amount to match the AVAX stake. Given typical AVAX and QI prices, this 10% margin can represent a shortfall of roughly 20 AVAX worth of QI, which is likely more lenient than intended.

## Vulnerability Details
In the `registerWithPrevalidatedQiStake` function, the `expectedQiAmount` is calculated based on the ratio of the AVAX price to the QI price, scaled for 201 AVAX (200 + 1 fee). The `require` statement imposes a check that qiAmount be at least 90% of expectedQiAmount. Depending on market prices, that 10% difference can equate to a sizable real-world value (approximately 20 AVAX).

```solidity
/ignit-cyfrin/ignite/src/Ignite.sol:386
386:         // 200 AVAX + 1 AVAX fee
387:         uint expectedQiAmount = uint(avaxPrice) * 201e18 / uint(qiPrice); // qi amount
388: 
389:         require(qiAmount >= expectedQiAmount * 9 / 10); // @audit 20 avax difference
390: 
```

Let say the AVAX and QI prices are as follow:

```shell
AVAX price = 3457371445
QI price = 1303053
```

The QI amount without the 10% margin.

```shell
QI amount = (3457371445 * 201e18 / 1303053)

QI amount = 533310356865760640587911
```

The QI amount with the 10% margin.

```shell
QI amount = (3457371445 * 201e18 / 1303053) * 9 / 10

QI amount = 479979321179184576529120
```

Difference:
```shell
QI difference = (533310356865760640587911 - 479979321179184576529120)
QI difference = (53331035686576064058791 / 1e18) ≈ 20 avax
```

This margin can result in a shortfall of roughly 20 AVAX worth of QI, which is larger than likely intended.


## Impact
By requiring only 90% of the intended QI amount, the contract may accept stakes that are missing the equivalent of approximately 20 AVAX. This weakens the  assumptions of the staking mechanism. 
## Tools Used
Manual Review
## Recommendations
Use a Tighter Threshold: Replace `9/10` with `99/100` or a similarly tighter bound.





## [L-1] Missing checks and In-Consistency  

## Summary
`registerWithStake` and `registerWithPrevalidatedQiStake` in the Ignite contract apply inconsistent validation for `avaxPrice` and `qiPrice`:
- **`registerWithStake`** enforces `require(qiPrice > 0 && avaxPrice > qiPrice)`. 
- **`registerWithPrevalidatedQiStake`** enforces `require(avaxPrice > 0 && qiPrice > 0)`, **but** does not check `avaxPrice > qiPrice`.

As a result, there is a mismatch in requirements that may cause inconsistent behavior across different registration methods.

## Vulnerability Details

In `registerWithStake` function the `avaxPrice > qiPrice` check is enforced.
```solidity
/ignit-cyfrin/ignite/src/Ignite.sol:222
222:         require(qiPrice > 0 && avaxPrice > qiPrice); // @audit what if the QI price surpass AVAX price ?
```
However, this means the function will revert if avaxPrice <= qiPrice, preventing the call entirely.

In `registerWithPrevalidatedQiStake` function:
```solidity
/ignit-cyfrin/ignite/src/Ignite.sol:382
382:         require(avaxPrice > 0 && qiPrice > 0); // @audit missing check for avaxPrice > qiPrice
```
Here, there is no requirement that `avaxPrice` be greater than `qiPrice`.
If the QI price surpasses the AVAX price, `registerWithPrevalidatedQiStake` could still proceed, while `registerWithStake` would fail under identical conditions.

## Impact
•	Inconsistency in Usage: Users who meet the price requirement for one function may fail for the other. This discrepancy could cause confusion or unexpected transaction failures when switching between different staking registration methods.
•	Potential Logic Flaw: If the business logic depends on avaxPrice being strictly greater than qiPrice, calls to `registerWithPrevalidatedQiStake` could allow situations that the contract otherwise intends to block.
    
## Tools Used
Manual Review
## Recommendations
1.	Standardize Requirements:
	• Ensure both `registerWithStake` and `registerWithPrevalidatedQiStake` follow the same condition if the design intends to require `avaxPrice > qiPrice`.
2.	Explicit Checks:
	• For registerWithStake, add require(avaxPrice > 0) explicitly if it’s necessary for clarity (though avaxPrice > qiPrice already implies avaxPrice > 0).
	• For registerWithPrevalidatedQiStake, include require(avaxPrice > qiPrice) if the same logic is required across all staking methods.