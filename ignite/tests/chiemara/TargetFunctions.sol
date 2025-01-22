// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
  

function clampLte(uint256 a, uint256 b) internal pure returns (uint256) {
        if (!(a <= b)) {
            uint256 value = a % (b + 1);
            return uint256(value);
        }
        return uint256(a);
    }
    function register_With_Stake(uint256 amount) public {
        amount = clampLte(25 ether,1500 ether);
        address user = users[0];
        
        vm.prank(user);
        ignite.registerWithStake{value:amount}("NodeID-1", blsPoP, 86400 * 14);
        totalEthStaked +=amount;
        uint qiAmount = uint(2_000_000_000) * (2000e18 - amount) / uint(1_000_000) / 10;
        totalQIStaked +=qiAmount;
    }





}
