// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {IgniteStorage} from "../../src/IgniteStorage.sol";
event LogUint(uint);

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    function _registerWithChecks(bool feePaid, uint msgValue) internal {
        uint subsidisationAmount;
        if (feePaid) {
            subsidisationAmount = 2000e18;
        } else {
            subsidisationAmount = 2000e18 - msgValue;
        }
        gostTotalSubsidisedAmount += subsidisationAmount;
    }

    function register_with_stake(
        uint256 userIndex,
        uint256 amountIndex,
        uint validationDurationIndex
    ) public {
        amountIndex = boundValue(amountIndex, 0, amountArr.length);
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        ); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint amount = amountArr[amountIndex];
        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint qiAmount = (uint(avaxPrice) * (2000e18 - amount)) /
            uint(qiPrice) /
            10;
        totalQIStaked += qiAmount;
        totalEthStaked += amount;

        string memory nodeIdStr = string(
            abi.encodePacked(
                "NodeID-",
                block.prevrandao,
                block.number,
                block.timestamp,
                userIndex
            )
        );
        vm.prank(user);
        ignite.registerWithStake{value: amount}(
            nodeIdStr,
            blsPoP,
            validationDuration
        );
        nodeIds.push(nodeIdStr);
        isRegisteredCalled = true;
        _registerWithChecks(false, amount);
    }
    function register_with_erc20_fee(
        uint256 userIndex,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        ); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint registrationFee = ignite.getRegistrationFee(validationDuration);

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint tokenAmount = (uint(avaxPrice) * registrationFee) /
            uint(qiPrice) /
            10 ** (18 - qi.decimals());
        uint amount = (tokenAmount * qiPriceMultiplier) / 10_000;
        totalQIStaked += amount;

        string memory nodeIdStr = string(
            abi.encodePacked(
                "NodeID-",
                block.prevrandao,
                block.number,
                block.timestamp,
                userIndex
            )
        );

        vm.prank(user);
        ignite.registerWithErc20Fee(
            address(qi),
            nodeIdStr,
            blsPoP,
            validationDuration
        );
        nodeIds.push(nodeIdStr);
        isRegisteredCalled = true;
        _registerWithChecks(true, 0);
    }

    function register_with_prevalidated_qiStake(
        uint256 userIndex,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        );
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];

        vm.prank(admin);
        ignite.grantRole(
            keccak256("ROLE_REGISTER_WITH_FLEXIBLE_PRICE_CHECK"),
            user
        );

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        // 200 AVAX + 1 AVAX fee = 201e18
        uint expectedQiAmount = (uint(avaxPrice) * 201e18) / uint(qiPrice);

        uint qiAmount = (expectedQiAmount * 9) / 10;

        totalQIStaked += qiAmount;

        string memory nodeIdStr = string(
            abi.encodePacked(
                "NodeID-",
                block.prevrandao,
                block.number,
                block.timestamp,
                userIndex
            )
        );

        vm.prank(user);
        ignite.registerWithPrevalidatedQiStake(
            address(user),
            nodeIdStr,
            blsPoP,
            validationDuration,
            qiAmount
        );
        _registerWithChecks(false, 0);
        nodeIds.push(nodeIdStr);
        isRegisteredCalled = true;
    }
    function register_without_collateral(
        uint256 userIndex,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length + 1
        );
        uint256[5] memory _durations = [
            durations[0],
            durations[1],
            durations[2],
            durations[3],
            86400 * 365
        ];
        uint validationDuration = _durations[validationDurationIndex];

        address user = users[userIndex];

        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_REGISTER_WITHOUT_COLLATERAL"), user);

        string memory nodeIdStr = string(
            abi.encodePacked(
                "NodeID-",
                block.prevrandao,
                block.number,
                block.timestamp,
                userIndex
            )
        );

        vm.prank(user);
        ignite.registerWithoutCollateral(
            nodeIdStr,
            blsPoP,
            validationDuration
        );
        nodeIds.push(nodeIdStr);
    }

    function register_with_avax_fee(
        uint256 userIndex,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        );
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint amount = ignite.getRegistrationFee(validationDuration);
        gostMinimumContractBalance += amount;
        totalEthStaked += amount;

        string memory nodeIdStr = string(
            abi.encodePacked(
                "NodeID-",
                block.prevrandao,
                block.number,
                block.timestamp,
                userIndex
            )
        );

        vm.prank(user);
        ignite.registerWithAvaxFee{value: amount}(
            nodeIdStr,
            blsPoP,
            validationDuration
        );
        nodeIds.push(nodeIdStr);
        isRegisteredCalled = true;
        _registerWithChecks(true, amount);
    }

    function withdraw_eth(uint amount) public {
        uint minBal = ignite.minimumContractBalance();
        amount = boundValue(
            amount,
            minBal + 1,
            address(ignite).balance - minBal + 1
        );

        totalEthStaked -= amount;
        vm.prank(admin);
        ignite.withdraw(amount);
    }
    function release_locked_tokens_failed(uint256 nodeIdIndex) public {
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            ,
            ,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        if (!withdrawable) {
            if (feePaid) {
                gostTotalSubsidisedAmount -= 2000e18;

                vm.prank(admin);
                ignite.releaseLockedTokens{value: 0}(
                    nodeId,
                    true // bool failed
                );
            } else {
                if (
                    tokenDeposits.tokenAmount > 0 && tokenDeposits.avaxAmount > 0
                ) {
<<<<<<< Updated upstream
                vm.prank(admin);
                ignite.releaseLockedTokens{value: tokenDeposits.avaxAmount}(
                    nodeId,
                    true // bool failed
                );
                }else{
=======
>>>>>>> Stashed changes
                    failRegistrationIndices.push(nodeId);

                    gostTotalSubsidisedAmount -=
                        2000e18 -
                        tokenDeposits.avaxAmount;

                totalEthStaked += tokenDeposits.avaxAmount;
                gostMinimumContractBalance += tokenDeposits.avaxAmount;

                vm.prank(admin);
                ignite.releaseLockedTokens{value: tokenDeposits.avaxAmount}(
                    nodeId,
                    true // bool failed
                );
                }
            }
        }
        releaseLockTokenFailedCalled = true;
    }

    function release_locked_tokens_success(uint256 nodeIdIndex) public {
        if (!isRegisteredCalled) return;
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            ,
            ,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        if (!withdrawable) {
            if (feePaid) {
                gostTotalSubsidisedAmount -= 2000e18;

                if (tokenDeposits.avaxAmount > 0) {
                    successRegistrationIndices.push(registrationIndex);
                    totalEthStaked -= tokenDeposits.avaxAmount;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                    avaxFee += tokenDeposits.avaxAmount;
                    gostMinimumContractBalance -= tokenDeposits.avaxAmount;
                } else {
                    successRegistrationIndices.push(registrationIndex);
                    totalQIStaked -= tokenDeposits.tokenAmount;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                    tokenFee += tokenDeposits.tokenAmount;
                }
            } else {
                gostTotalSubsidisedAmount -= 2000e18 - tokenDeposits.avaxAmount;

                if (ignite.qiRewardEligibilityByNodeId(nodeId)) {
                    uint fee = tokenDeposits.tokenAmount / 201;

                    totalQIStaked -= fee;

                    tokenFee += fee;

                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                } else {
                    uint msgValue = tokenDeposits.avaxAmount + 10;
                    totalEthStaked += msgValue;
                    gostMinimumContractBalance += msgValue;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: msgValue}(
                        nodeId,
                        false // bool failed
                    );
                }
            }
        }
        releaseLockTokenSuccessCalled = true;
    }

    function release_locked_tokens_slash(uint256 nodeIdIndex) public {

        
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            uint qiSlashPercentage,
            uint avaxSlashPercentage,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);
        bool isNoCollateral = tokenDeposits.avaxAmount > 0 || tokenDeposits.tokenAmount > 0;
        uint msgValue = tokenDeposits.avaxAmount;
        if(isNoCollateral){
      
        if (!withdrawable) {
            if (!feePaid && msgValue != 0) {
                vm.prank(admin);
                ignite.releaseLockedTokens{value: msgValue}(
                    nodeId,
                    false // bool failed
                );
                        gostTotalSubsidisedAmount -= 2000e18 - tokenDeposits.avaxAmount;

                totalEthStaked += msgValue;

                if (qiSlashPercentage > 0) {
                    uint qiSlashAmount = (tokenDeposits.tokenAmount *
                        qiSlashPercentage) / 10_000;
                    tokenSlash += qiSlashAmount;
                    totalQIStaked -= qiSlashAmount;
                }

                if (avaxSlashPercentage > 0) {
                    uint avaxSlashAmount = (tokenDeposits.avaxAmount *
                        avaxSlashPercentage) / 10_000;

                    gostMinimumContractBalance += msgValue - avaxSlashAmount;
                    avaxSlash += avaxSlashAmount;
                    totalEthStaked -= avaxSlashAmount;
                } else {
                    gostMinimumContractBalance += msgValue;
                }
            }else if(feePaid){
                 vm.prank(admin);
                ignite.releaseLockedTokens{value: 0}(
                    nodeId,
                    false // bool failed
                );

                gostTotalSubsidisedAmount -= 2000e18;

            if (tokenDeposits.avaxAmount > 0) {
                avaxFee += tokenDeposits.avaxAmount;
                gostMinimumContractBalance -= tokenDeposits.avaxAmount;
                totalEthStaked -= tokenDeposits.avaxAmount;
            } else {
                tokenFee += tokenDeposits.tokenAmount;

                totalQIStaked -= tokenDeposits.tokenAmount;
            }            
            }
        }
        releaseLockTokenSlashedCalled = true;
        }
    }

    function redeem(uint256 nodeIdIndex, uint256 userIndex) public {
        if (!releaseLockTokenSuccessCalled) return;
        userIndex = boundValue(userIndex, 0, users.length);

        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        address user = users[userIndex];

        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            uint validationDuration,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            uint rewardAmount,
            uint qiSlashPercentage,
            uint avaxSlashPercentage,
            bool stashed,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        if (withdrawable) {



        if(feePaid) {
            if (tokenDeposits.avaxAmount > 0) {
                gostMinimumContractBalance -= tokenDeposits.avaxAmount;
                totalEthStaked -= tokenDeposits.avaxAmount;
            } else {
                totalQIStaked -= tokenDeposits.tokenAmount;
            }

               vm.prank(user);
            ignite.redeemAfterExpiry(nodeId);
            return;
        }

            uint avaxRedemptionAmount;
            uint qiRedemptionAmount;
            if (stashed) {
                avaxRedemptionAmount =
                    tokenDeposits.avaxAmount -
                    (tokenDeposits.avaxAmount * avaxSlashPercentage) /
                    10_000;
                qiRedemptionAmount = tokenDeposits.tokenAmount - tokenDeposits.tokenAmount * qiSlashPercentage / 10_000;

                gostMinimumContractBalance -= avaxRedemptionAmount;


            } else {
                avaxRedemptionAmount = tokenDeposits.avaxAmount + rewardAmount;
                qiRedemptionAmount = tokenDeposits.tokenAmount;

                if (ignite.qiRewardEligibilityByNodeId(nodeId)) {
                    qiRedemptionAmount += vr.claimRewards(
                        validationDuration,
                        tokenDeposits.tokenAmount
                    );
                }

                gostMinimumContractBalance -= avaxRedemptionAmount;
            }

            if(avaxRedemptionAmount > 0){
                totalEthStaked -= avaxRedemptionAmount;

            }

            if(qiRedemptionAmount > 0){
                totalQIStaked -= qiRedemptionAmount;
            }



            vm.prank(user);
            ignite.redeemAfterExpiry(nodeId);
        }
    }
}
