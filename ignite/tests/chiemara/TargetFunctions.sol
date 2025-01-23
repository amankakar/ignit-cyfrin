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
    function register_With_Stake(uint256 userIndex, uint256 amount,uint256 nodeId) public {
        userIndex = clampLte(0, users.length-1);

        amount = clampLte(25 ether,1500 ether);
        if (amount % 1e9 != 0) {
            amount - (amount % 1e9);
        }
        address user = users[userIndex];
        
        uint qiAmount = uint(2_000_000_000) * (2000e18 - amount) / uint(1_000_000) / 10;
        totalQIStaked +=qiAmount;
        totalEthStaked +=amount;
        vm.prank(user);
        ignite.registerWithStake{value:amount}(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, 86400 * 14);
    }
    function register_With_Erc20_Fee(uint256 userIndex, uint256 amount,uint256 nodeId) public {
        userIndex = clampLte(0, users.length-1);

        address user = users[userIndex];
        
        uint qiAmount = amount * 10_000 / 10_000;
        totalQIStaked +=qiAmount;
        vm.prank(user);
        ignite.registerWithErc20Fee(address(qi),string(abi.encodePacked("NodeID-",nodeId)), blsPoP, 86400 * 14);
    }
    function register_With_Prevalidated_QiStake(uint256 userIndex, uint256 amount,uint256 nodeId) public {
        userIndex = clampLte(0, users.length-1);

        address user = users[userIndex];
        
        uint qiAmount = amount * 10_000 / 10_000;
        totalQIStaked +=qiAmount;
        vm.prank(user);
        ignite.registerWithPrevalidatedQiStake(address(user),string(abi.encodePacked("NodeID-",nodeId)), blsPoP, 86400 * 14);
    }
    function register_Without_Collateral(uint256 userIndex, uint256 nodeId) public {
        userIndex = clampLte(0, users.length-1);

        address user = users[userIndex];
        
        vm.prank(user);
        ignite.registerWithoutCollateral(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, 86400 * 14);
    }

      function register_With_Avax_Fee(uint256 userIndex, uint validationDuration,uint256 nodeId) public {
        userIndex = clampLte(0, users.length-1);
        validationDuration = clampLte(1209600, 7257600); // 2-12 weeks

        address user = users[userIndex];
        uint amount = ignite.getRegistrationFee(validationDuration);
        totalEthStaked +=amount;
        
        vm.prank(user);
        ignite.registerWithAvaxFee{value:amount}(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration);
    }

    function withdraw_eth(uint amount) public{

        uint minBal = ignite.minimumContractBalance();
        amount = clampLte(minBal+1, address(ignite).balance-minBal);
        
        totalEthStaked -=amount;
        vm.prank(admin);
        ignite.withdraw(amount);
    }
    // function release_Locked_Tokens(uint256 nodeId) public{
    //     amount = clampLte(0,totalEthStaked);

    //     uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
    //     require(registrationIndex != 0);

    //     Registration storage registration = registrations[registrationIndex];
    //     registration.feePaid();
    //     totalEthStaked += amount;
    //     vm.prank(admin);
    //     ignite.releaseLockedTokens{value:0}(
    //          string(abi.encodePacked("NodeID-",nodeId)),
    //         false
    //     );
    // }
  
}