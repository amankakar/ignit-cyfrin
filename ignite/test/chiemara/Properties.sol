// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

import {IgniteStorage} from "../../src/IgniteStorage.sol";
event LogAsad(uint256);

abstract contract Properties is BeforeAfter, Asserts {
   function echidna_check_eth_balance() external  view returns(bool){
        return address(ignite).balance == totalEthStaked;
    }
   function echidna_check_minimum_eth_balance() external  view returns(bool){
        return ignite.minimumContractBalance() == gostMinimumContractBalance;
    }
   function echidna_check_qi_balance() external view returns(bool){
        return  qi.balanceOf(address(ignite)) ==  totalQIStaked;
    }
   function echidna_check_fail_registration_withdrawal() external view returns(bool){
        if(releaseLockTokenFailedCalled){
            for(uint i = 0; i < failRegistrationIndices.length; i++){
                (,,,,,,,,,bool withdrawable) = ignite.registrations(failRegistrationIndices[i]);
                    if(!withdrawable){
                        return false;
                    }   
            }
        }
        return true;
    }
    function echidna_check_success_registration_withdrawal() external  returns(bool){
        if(releaseLockTokenSuccessCalled){
        emit LogAsad(avaxFee);
        emit LogAsad(tokenFee);
            return address(FEE_RECIPIENT).balance == avaxFee && qi.balanceOf(FEE_RECIPIENT) == tokenFee;
        }
        return true;
    }
    // function echidna_check_success_slashed() external view returns(bool){
    //     if(releaseLockTokenSlashedCalled){
    //         return address(SLASHED_TOKEN_RECIPIENT).balance == avaxSlash && qi.balanceOf(SLASHED_TOKEN_RECIPIENT) == tokenSlash;
    //     }
    //     return true;
    // }
}