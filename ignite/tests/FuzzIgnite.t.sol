// SPDX-License-Identifier: Apache

pragma solidity ^0.8.24;

import {Ignite} from "../src/Ignite.sol";
import {PriceFeed} from "./contracts/PriceFeed.sol";
import {StakedAvax} from "./contracts/StakedAvax.sol";
import {FaucetToken} from "./contracts/FaucetToken.sol";

import "@crytic/properties/contracts/util/Hevm.sol";

contract FuzzIgnite {
    address admin = address(0x23457643);
    address[] internal users;

    Ignite ignite;
    FaucetToken qi;
    StakedAvax sAvax;
    PriceFeed qiPriceFeed;
    PriceFeed avaxPriceFeed;
    // ghost variable
    uint256 totalStaked;
    mapping(address => uint256) public staked;
    // mapping(address => uint256) public claimed;
    constructor() {
        users.push(address(0x1));
        users.push(address(0x2));
        users.push(address(0x3));
        hevm.prank(admin);
         qiPriceFeed = new PriceFeed(120);
        hevm.prank(admin);
         avaxPriceFeed = new PriceFeed(120);
        hevm.prank(admin);
        sAvax = new StakedAvax();
        hevm.prank(admin);
        qi = new FaucetToken("BENQI","QI",18);
        hevm.prank(admin);
        ignite = new Ignite();
        hevm.prank(admin);
        ignite.initialize(
            address(sAvax),
            address(qi),
            address(avaxPriceFeed),
            120,
            address(qiPriceFeed),
            180,
            25 ether, // min eth
            1500 ether // max eth
        );
    for (uint i = 0; i < users.length; i++) {
        hevm.prank(admin);
        qi.mint(users[i], 10000000000000000 ether); // mint qi
        hevm.deal(users[i],10000000000000000 ether); // mint eth
        hevm.prank(users[i]);
        qi.approve(address(ignite), type(uint256).max);
    }
        hevm.prank(admin);
        ignite.configurePriceFeed(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,address(avaxPriceFeed),120);

    }

    function register_With_Stake(uint256 userIndex, uint256 amount,uint256 ethAmount) public {
        
        hevm.assume(userIndex < users.length);
        address user = users[userIndex];
        hevm.assume(amount <= qi.balanceOf(user));
        hevm.assume(
            ethAmount <= address(user).balance &&
           ethAmount >= 25 ether &&
            ethAmount <= 1500 ether &&
            ethAmount % 1e9 == 0
            );

        // Set AVAX price to $20 and QI price to $0.01
        avaxPriceFeed.setPrice(2_000_000_000);
        qiPriceFeed.setPrice(1_000_000);
        // assert(address(ignite.priceFeeds(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) == address(0));
        hevm.prank(user);
        ignite.registerWithStake{value:ethAmount}("NodeID-1", bytes("0xasad97"), 86400 * 14);
        // staked[user] += amount;
        // totalStaked += amount;
        // hevm.warp(block.timestamp + 30 days);


    }

    // function claim_vested_token(uint256 userIndex, uint16 _days) public {
    //     hevm.assume(userIndex < users.length);
    //     address user = users[userIndex];
    //     // increase time
    //     hevm.warp(block.timestamp + _days);

    //     (uint256 claimableAmount, ) = SecondSwap_StepVesting(vesting).claimable(
    //         user
    //     );

    //     hevm.prank(user);
    //     SecondSwap_StepVesting(vesting).claim();

    //     claimed[user] += claimableAmount;
    // }
  

    // function reallocate_vested_token(uint8 userIndex,uint8 userIndex2,uint256 amount) public {
    //     hevm.assume(userIndex < users.length);
    //     address user = users[userIndex];

    //     uint256 total =  vested[user] - claimed[user]; 
    //     hevm.assume(amount < total);

    //     hevm.assume(userIndex2 < users.length);
    //     address user2 = users[userIndex2];
        
    //     hevm.prank(admin);
    //     vestingDeployer.transferVesting(user,user2,amount,vesting,"myVestingId");
        
    //     vested[user2] += amount;
    //     vested[user] -= amount;
    // }

    // function echidna_vesting_balance() public view returns(bool){

    //     uint256 amount;
    //     for (uint256 i = 0; i < users.length; i++) {
    //         address user = users[i];
    //         if (vested[user] > 0) {
    //             amount += (vested[user] - claimed[user]);
    //         }
    //     }
    //     assert(token.balanceOf(vesting) == amount);
    //     return true;
    // }
    // function echidna_vesting_total() public view returns(bool){
    //     for (uint256 i = 0; i < users.length; i++) {
    //         address user = users[i];
    //         if (vested[user] > 0) {
    //             uint256 total = SecondSwap_StepVesting(vesting).total(user);
    //             assert(total == vested[user]);
    //         }
    //     }

    //             return true;

    // }

    // function echidna_claimed_balance() public view returns(bool){
    //     for (uint256 i = 0; i < users.length; i++) {
    //         address user = users[i];
    //         if (claimed[user] > 0) {
    //             assert(token.balanceOf(user) == claimed[user]);
    //         }
    //     }

    //             return true;

    // }


     function echidna_avaliable() public view returns(bool){
               assert(qi.balanceOf(address(ignite)) == 0);

    //     for (uint256 i = 0; i < users.length; i++) {
    //         address user = users[i];
    //         if (vested[user] > 0) {
    //             assert(SecondSwap_StepVesting(vesting).available(user) == vested[user] - claimed[user]);
    //             assert(SecondSwap_StepVesting(vesting).total(user) == vested[user]);
    //         }
    //     }
                return true;

    }
}
