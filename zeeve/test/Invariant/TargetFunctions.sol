// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {StakingContract} from "../../src/staking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    // All the handler function which will calls the target contract which we need to fuzz test.
    // @note : All the functions here will be added to `CryticToFoundry` setUp function in targetSelector


    function stake_with_erc20(uint8 index) public {
        uint256 userIndex = boundValue(uint256(index), 0, users.length - 1);
        uint256 durationIndex = boundValue(
            uint256(index),
            0,
            durations.length - 1
        );

        uint256 stakeAmount = _getRegistrationFee(durations[durationIndex]);
        uint256 avaxFee = stakingInstance.calculateHostingFee(
            durations[durationIndex]
        );
        stakeAmount = stakingInstance.convertAvaxToToken(
            qiTokenAddress,
            stakingInstance.avaxStakeAmount() + avaxFee
        );
        emit Logs1("avax fee");
        emit Logs(avaxFee);
        emit Logs1("stakingInstance.avaxStakeAmount()");
        emit Logs(stakingInstance.avaxStakeAmount());
        emit Logs1("avax stakeAmount");
        emit Logs(stakeAmount);
        // uint count = stakingInstance.getUserStakeCount(users[userIndex]);

        //    uint256 initBal= IERC20(qiTokenAddress).balanceOf(stakingInstance);
        vm.prank(users[userIndex]);
        stakingInstance.stakeWithERC20(
            durations[durationIndex],
            stakeAmount,
            qiTokenAddress
        );
        ghost_Qi_deposits += stakeAmount; //initBal - IERC20(qiTokenAddress).balanceOf(users[userIndex]) ;//stakeAmount;// @audit-issue : Note here the Fee is also included in ghost variable as the Fee amount is not yet transfered to zeeve wallet
        usersQiDepsoits[users[userIndex]] += stakeAmount;
        isStakeERC20Called = true;
        userRecordIndexes[users[userIndex]] += 1;

        emit Logs1("avax ghost_Qi_deposits");

        emit Logs(ghost_Qi_deposits);
        // emit Logs(IERC20(qiTokenAddress).balanceOf(address(stakingInstance)));
        // revert();
    }
function stake_with_avax(uint8 index) public {
        uint256 userIndex = 1;//boundValue(uint256(index), 0, users.length - 1);
        uint256 durationIndex = boundValue(
            uint256(index),
            0,
            durations.length - 1
        );

        uint256 stakeAmount = _getRegistrationFee(durations[durationIndex]);
        stakeAmount = stakingInstance.avaxStakeAmount();
        uint256 avaxFee = stakingInstance.calculateHostingFee(
            durations[durationIndex]
        );

        // cache user AVAX balance than we will find out the AVAX amount used in registeration
        uint256 initialBalance = address(users[userIndex]).balance;
        uint256 msgValue = stakeAmount + avaxFee;
        address[] memory path = new address[](2);
        path[0] = ghost_joeRouter.WAVAX();
        path[1] = address(qiTokenAddress);

        uint256[] memory amountsOut = ghost_joeRouter.getAmountsOut(
            stakeAmount,
            path
        );
        // emit Logs(users[userIndex]);

        // uint count = stakingInstance.getUserStakeCount(users[userIndex]);
        // emit Logs(count);


        vm.prank(users[userIndex]);
        stakingInstance.stakeWithAVAX{value: msgValue}(
            durations[durationIndex]
        );
        // uint256 count = stakingInstance.getUserStakeCount(users[userIndex]);
        // emit Logs(count);
        userRecordIndexes[users[userIndex]] += 1;

        ghost_staking_eth_bal += avaxFee; // Fee amount in AVAX
        // Find the Actual QI balance after refund
        uint256 balanceChanged = initialBalance -
            address(users[userIndex]).balance;
        balanceChanged = balanceChanged - avaxFee;
        // Expected Qi Amount
        uint256 expectedQiAmount = stakingInstance.convertTokenToQi(
            AVAX,
            balanceChanged
        );
        uint256 slippageFactor = 100 - stakingInstance.slippage(); // Convert slippage percentage to factor
        uint256 amountOutMin = (expectedQiAmount * slippageFactor) / 100; // Apply slippage
        ghost_Qi_deposits += amountsOut[amountsOut.length - 1];
        // emit Logs1("amount out ");
        // emit Logs(amountsOut[amountsOut.length - 1]);
        usersQiDepsoits[users[userIndex]] += amountsOut[amountsOut.length - 1];
        usersETHFee[users[userIndex]] += balanceChanged;
        isStakeETHCalled = true;
        // revert();
        emit Logs1("Avax Call Completed");

    }

    function registerNode(uint8 index, uint256 NodeID) public {
        if (isStakeETHCalled && isStakeERC20Called) {
            uint256 userIndex =1;// boundValue(uint256(index), 0, users.length - 1);
            uint256 recordLength = userRecordIndexes[users[userIndex]];
                emit Logs1("Record Length");
                emit Logs(recordLength);

            if (recordLength > 0) {
                StakingContract.StakeRecord[] memory userRecord = stakingInstance
                    .getStakeRecords(users[userIndex]);
                    uint256 recordIndex = boundValue(
                    uint256(index),
                    0,
                    userRecord.length
                );
                emit Logs1("Record Index");
                emit Logs(recordIndex);

                emit Logs1("Record Hosting Fee");
                emit Logs(userRecord[recordIndex].hostingFeePaid);

                if (userRecord[recordIndex].hostingFeePaid!=0) {
                    vm.prank(zeeveSuperAdmin);
                    stakingInstance.registerNode(
                        users[userIndex],
                        string(abi.encodePacked("NodeID-", NodeID)),
                        blsPoP,
                        recordIndex
                    );
                    ghost_zeeveWallet_fee += userRecord[recordIndex].hostingFeePaid;
                    ghost_Qi_deposits -= userRecord[recordIndex].amountStaked;
                    if (userRecord[recordIndex].tokenType == AVAX) {
                        ghost_staking_eth_bal -= userRecord[recordIndex].hostingFeePaid;
                    } else {
                        ghost_Qi_deposits -= userRecord[recordIndex].hostingFeePaid;
                    }
                    emit Logs1("Register Node Completed");

                }
            }

        }
    }
    

    // function boundValue(uint256 a, uint256 b) internal pure returns (uint8) {
    //     if (!(a <= b)) {
    //         uint256 value = a % (b + 1);
    //         return uint8(value);
    //     }
    //     return uint8(a);
    // }
}
