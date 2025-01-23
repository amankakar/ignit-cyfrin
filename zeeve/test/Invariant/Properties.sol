// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
abstract contract Properties is BeforeAfter, Asserts {
    // example property test that gets run after each call in sequence So add All the invariant which we need to check here
    function echidna_test_simle() public view returns (bool){
        return stakingInstance.avaxStakeAmount() == 1 ether &&  stakingInstance.isTokenAccepted(AVAX);
    }

    function echidna_check_stacking_eth_bal() external  returns(bool){
        if(isStakeETHCalled){
            emit Logs(ghost_staking_eth_bal);
        return address(stakingInstance).balance == ghost_staking_eth_bal;
        }else {
        return true;
        }
    }

        function echidna_check_stacking_qi_bal() public  returns(bool){
        if(isStakeERC20Called){
            emit Logs(ghost_Qi_deposits);
        return  IERC20(qiTokenAddress).balanceOf(address(stakingInstance)) == ghost_Qi_deposits;
        }else {
        return true;
        }
    }
}