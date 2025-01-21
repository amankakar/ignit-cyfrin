// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {StakingContract} from "../../src/staking.sol";


abstract contract TargetFunctions is BaseTargetFunctions, Properties {

    // All the handler function which will calls the target contract which we need to fuzz test.
    // @note : All the functions here will be added to `CryticToFoundry` setUp function in targetSelector  
    function call_init() external {
        ghost_avaxStakeAmount = initialStakingAmount;

    }
      
    function clampLte(uint256 a, uint256 b) internal pure returns (uint8) {
        if (!(a <= b)) {
            uint256 value = a % (b + 1);
            return uint8(value);
        }
        return uint8(a);
    }

}
