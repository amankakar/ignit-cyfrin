// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";



abstract contract Properties is BeforeAfter, Asserts {
    event LogUint(uint);
   function echidna_check_eth_balance() external view returns(bool){
        return address(ignite).balance == totalEthStaked;
    }
   function echidna_check_qi_balance() external  returns(bool){
    emit LogUint(totalQIStaked);
        return  qi.balanceOf(address(ignite)) ==  totalQIStaked;
    }
}