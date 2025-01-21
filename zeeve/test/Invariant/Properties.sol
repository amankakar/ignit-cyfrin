// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    // example property test that gets run after each call in sequence So add All the invariant which we need to check here
    function echidna_test_simle() public view returns (bool){
        return stakingInstance.avaxStakeAmount() == 1 ether &&  stakingInstance.isTokenAccepted(AVAX);
    }
}