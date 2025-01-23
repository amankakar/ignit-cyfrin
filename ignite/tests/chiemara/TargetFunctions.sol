// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
  

    function boundValue(uint256 value, uint256 min, uint256 max) public pure returns (uint256) {
        if (min > max) {
            (min, max) = (max, min); // Swap values if range is incorrect
        }
        
        uint256 range = max - min;  // Exclusive range calculation
        return min + (value % range);
    }
  

    function register_With_Stake(uint256 userIndex, uint256 amount,uint256 nodeId,uint validationDurationIndex) public {
        userIndex = boundValue(userIndex,0,users.length);
        validationDurationIndex = boundValue(validationDurationIndex,0,durations.length); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];
        
        address user = users[userIndex];
        amount = boundValue(amount,25 ether,1500 ether);
        if (amount % 1e9 != 0) {
            amount - (amount % 1e9);
        }
        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint qiAmount = uint(avaxPrice) * (2000e18 - amount) / uint(qiPrice) / 10;
        totalQIStaked +=qiAmount;
        totalEthStaked +=amount;
        vm.prank(user);
        ignite.registerWithStake{value:amount}(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration);
    }
    function register_With_Erc20_Fee(uint256 userIndex,uint256 nodeId, uint validationDurationIndex) public {
        userIndex = boundValue(userIndex,0, users.length);
        validationDurationIndex = boundValue(validationDurationIndex,0,durations.length); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint registrationFee =   ignite.getRegistrationFee(validationDuration);

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint tokenAmount = uint(avaxPrice) * registrationFee / uint(qiPrice) / 10 ** (18 - qi.decimals());
        uint amount = tokenAmount * qiPriceMultiplier / 10_000;
        totalQIStaked +=amount;
        vm.prank(user);
        ignite.registerWithErc20Fee(address(qi),string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration);
    }
    function register_With_Prevalidated_QiStake(uint256 userIndex,uint256 nodeId,uint validationDurationIndex) public {
        userIndex = boundValue(userIndex,0, users.length);
        validationDurationIndex = boundValue(validationDurationIndex,0,durations.length);
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];

        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_REGISTER_WITH_FLEXIBLE_PRICE_CHECK"),user);

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        // 200 AVAX + 1 AVAX fee = 201e18
        uint expectedQiAmount = uint(avaxPrice) * 201e18 / uint(qiPrice);

        uint qiAmount = expectedQiAmount * 9 / 10;

        totalQIStaked +=qiAmount;
        vm.prank(user);
        ignite.registerWithPrevalidatedQiStake(address(user),string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration,qiAmount);
    }
    function register_Without_Collateral(uint256 userIndex, uint256 nodeId,uint validationDurationIndex) public {
        userIndex = boundValue(userIndex,0, users.length);
        validationDurationIndex = boundValue(validationDurationIndex,0,durations.length);
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_REGISTER_WITHOUT_COLLATERAL"),user);

        vm.prank(user);
        ignite.registerWithoutCollateral(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration);
    }

      function register_With_Avax_Fee(uint256 userIndex, uint validationDurationIndex,uint256 nodeId) public {
        userIndex = boundValue(userIndex,0, users.length);
        validationDurationIndex = boundValue(validationDurationIndex,0,durations.length);
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint amount = ignite.getRegistrationFee(validationDuration);
        totalEthStaked +=amount;
        
        vm.prank(user);
        ignite.registerWithAvaxFee{value:amount}(string(abi.encodePacked("NodeID-",nodeId)), blsPoP, validationDuration);
    }

    function withdraw_eth(uint amount) public{

        uint minBal = ignite.minimumContractBalance();
        amount = boundValue(amount,minBal+1, address(ignite).balance-minBal+1);
        
        totalEthStaked -=amount;
        vm.prank(admin);
        ignite.withdraw(amount);
    }
    // function release_Locked_Tokens(uint256 nodeId) public{
    //     amount = boundValue(0,totalEthStaked);

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