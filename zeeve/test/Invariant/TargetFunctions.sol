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
        function stake_with_avax() public {
        uint256 userIndex = clampLte(0, users.length);
        uint256 durationIndex = clampLte(0, durations.length);

        uint256 stakeAmount = _getRegistrationFee(durations[durationIndex]);
        stakeAmount = stakingInstance.avaxStakeAmount();
        uint256 avaxFee = stakingInstance.hostingFeeAvax();

        // cache user AVAX balance than we will find out the AVAX amount used in registeration
        uint256 initialBalance = address(users[userIndex]).balance;
        uint256 msgValue = stakeAmount + avaxFee;
           address[] memory path = new address[](2);
            path[0] = ghost_joeRouter.WAVAX();
            path[1] = address(qiTokenAddress);

uint256[] memory amountsOut = ghost_joeRouter.getAmountsOut(stakeAmount ,path);

        vm.prank(users[userIndex]);
        stakingInstance.stakeWithAVAX{value: msgValue}(
            durations[durationIndex]
        );

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
        ghost_Qi_deposits += amountsOut[amountsOut.length-1];
        emit Logs1("amount out "); 
         emit Logs(amountsOut[amountsOut.length-1]); 
        usersQiDepsoits[users[userIndex]] += amountsOut[amountsOut.length-1];
        usersETHFee[users[userIndex]] += balanceChanged;
        isStakeETHCalled = true;
        // revert();
    }

        function stake_with_erc20() public {
        uint256 userIndex = clampLte(0, users.length);
        uint256 durationIndex = clampLte(0, durations.length);

        uint256 stakeAmount = _getRegistrationFee(durations[durationIndex]);
        uint256 avaxFee = stakingInstance.calculateHostingFee(durations[durationIndex]);
        stakeAmount = stakingInstance.convertAvaxToToken(qiTokenAddress , stakingInstance.avaxStakeAmount() + avaxFee);
         emit Logs1("avax fee");
         emit Logs(avaxFee); 
         emit Logs1("stakingInstance.avaxStakeAmount()");
         emit Logs(stakingInstance.avaxStakeAmount());
        emit Logs1("avax stakeAmount");      
         emit Logs(stakeAmount);

    //    uint256 initBal= IERC20(qiTokenAddress).balanceOf(stakingInstance);
        vm.prank(users[userIndex]);
        stakingInstance.stakeWithERC20(durations[durationIndex],stakeAmount , qiTokenAddress);
        ghost_Qi_deposits += stakeAmount ; //initBal - IERC20(qiTokenAddress).balanceOf(users[userIndex]) ;//stakeAmount;// @audit-issue : Note here the Fee is also included in ghost variable as the Fee amount is not yet transfered to zeeve wallet
        usersQiDepsoits[users[userIndex]] += stakeAmount;
        isStakeERC20Called = true;
                emit Logs1("avax ghost_Qi_deposits");      

        emit Logs(ghost_Qi_deposits);
        // emit Logs(IERC20(qiTokenAddress).balanceOf(address(stakingInstance)));
        // revert();

    }



    // function clampLte(uint256 a, uint256 b) internal pure returns (uint8) {
    //     if (!(a <= b)) {
    //         uint256 value = a % (b + 1);
    //         return uint8(value);
    //     }
    //     return uint8(a);
    // }
}
