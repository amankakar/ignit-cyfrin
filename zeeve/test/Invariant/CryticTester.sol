// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {TargetFunctions} from "./TargetFunctions.sol";
import {CryticAsserts} from "@chimera/CryticAsserts.sol";

// echidna . --contract CryticTester --config echidna.yaml
// medusa fuzz
contract CryticTester is TargetFunctions, CryticAsserts {
    constructor() payable {
        setup(); 
        // this contract will works with Echidna nd medusa , 
        // 1. so inside echidna command we need to pass this contract as a target contract
        // 2 . For medusa set this contract in : `targetContracts` 
    }
}