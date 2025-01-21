// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
        // this contract will works with foundry fuzzing
        targetContract(address(this)); // here we need to pass the address which will run fuzz test like handler , or we can also pass the target contract here

        // handler functions to target during invariant tests , add as many entry which we need to run in fuzz test i.e like all handler funcitons
    //   bytes4[] memory selectors = new bytes4[](1);
    //   selectors[0] = this.create_vesting.selector; // i.e create_vesting example function

    //   targetSelector(FuzzSelector({ addr: address(this), selectors: selectors }));
    }

    // function invariant_vesting_balance() public {
        // wrap all the invarnat function in assertTure so that underline echinda / medusa function works will with foundry
        // assertTrue(echidna_invariant_function());
    // }

}
