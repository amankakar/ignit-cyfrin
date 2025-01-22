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
    bytes public blsKey = hex"8d609cdd38ffc9ad01c91d1ae4fccb8cd6c75a6ad33a401da42283b0c3b59bbaf5abc172335ea4d9c31baa936818f0ab";

    bytes public blsSignature = hex"8c12c805e7dfe4bfe38be44685ee852d931d73b3c0820a1343d731909120cee4895f9b60990520a90d06a031a42e0f8616d415b543408c24be0da90d5e7fa8242f4fd32dadf34c790996ca474dbdbcd763f82c53880db19fd3b30d13cee278b4";

    bytes public   blsPoP = abi.encodePacked(blsKey, blsSignature);
    Ignite ignite;
    FaucetToken qi;
    StakedAvax sAvax;
    PriceFeed qiPriceFeed;
    PriceFeed avaxPriceFeed;
    // ghost variable
  uint256 totalEthStaked;
    uint256 totalQIStaked;
    constructor() {
        users.push(address(0x1));
        users.push(address(0x2));
        users.push(address(0x3));
        hevm.prank(admin);
         qiPriceFeed = new PriceFeed(1_000_000);
        hevm.prank(admin);
         avaxPriceFeed = new PriceFeed(2_000_000_000);
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
        // register_With_Stake();

    }

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
        
        hevm.prank(user);
         ignite.registerWithStake{value:amount}("NodeID-1", blsPoP, 86400 * 14);
        totalEthStaked +=amount;
        uint qiAmount = uint(2_000_000_000) * (2000e18 - amount) / uint(1_000_000) / 10;
        totalQIStaked +=qiAmount;
    }


    function echidna_check_eth_balance() external view returns(bool){
        return address(ignite).balance == totalEthStaked;
    }
   function echidna_check_qi_balance() external view returns(bool){
        return  qi.balanceOf(address(ignite)) ==  totalQIStaked;
    }
}
