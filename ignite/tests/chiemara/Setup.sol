// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";

import {Ignite} from "../../src/Ignite.sol";
import {PriceFeed} from "../contracts/PriceFeed.sol";
import {StakedAvax} from "../contracts/StakedAvax.sol";
import {FaucetToken} from "../contracts/FaucetToken.sol";

import {vm} from "@chimera/Hevm.sol";
    

abstract contract Setup is BaseSetup {
    address admin = address(0x23457643);
    address[] internal users;
    bytes public blsKey =
        hex"8d609cdd38ffc9ad01c91d1ae4fccb8cd6c75a6ad33a401da42283b0c3b59bbaf5abc172335ea4d9c31baa936818f0ab";

    bytes public blsSignature =
        hex"8c12c805e7dfe4bfe38be44685ee852d931d73b3c0820a1343d731909120cee4895f9b60990520a90d06a031a42e0f8616d415b543408c24be0da90d5e7fa8242f4fd32dadf34c790996ca474dbdbcd763f82c53880db19fd3b30d13cee278b4";

    bytes public blsPoP = abi.encodePacked(blsKey, blsSignature);
    Ignite ignite;
    FaucetToken qi;
    StakedAvax sAvax;
    PriceFeed qiPriceFeed;
    PriceFeed avaxPriceFeed;
    // ghost variable
    uint256 totalEthStaked;
    uint256 totalQIStaked;
    uint public qiPriceMultiplier = 10_000;

    uint256[] public durations;
    uint public constant VALIDATION_DURATION_TWO_WEEKS = 86400 * 7 * 2;
    uint public constant VALIDATION_DURATION_FOUR_WEEKS = 86400 * 7 * 4;
    uint public constant VALIDATION_DURATION_EIGHT_WEEKS = 86400 * 7 * 8;
    uint public constant VALIDATION_DURATION_TWELVE_WEEKS = 86400 * 7 * 12;
    uint[] public amountArr = [
        25 ether, 50 ether, 75 ether, 100 ether, 125 ether, 
150 ether, 175 ether, 200 ether, 225 ether, 250 ether, 
275 ether, 300 ether, 325 ether, 350 ether, 375 ether, 
400 ether, 425 ether, 450 ether, 475 ether, 500 ether];
    function boundValue(uint256 value, uint256 min, uint256 max) public pure returns (uint256) {
        return min + (value % (max - min));
    }
  

    function setup() internal virtual override {
        users.push(address(0x1));
        users.push(address(0x2));
        users.push(address(0x3));
        vm.prank(admin);
        qiPriceFeed = new PriceFeed(1_000_000);
        vm.prank(admin);
        avaxPriceFeed = new PriceFeed(2_000_000_000);
        vm.prank(admin);
        sAvax = new StakedAvax();
        vm.prank(admin);
        qi = new FaucetToken("BENQI", "QI", 18);
        vm.prank(admin);
        ignite = new Ignite();
        vm.prank(admin);
        ignite.initialize(
            address(sAvax),
            address(qi),
            address(avaxPriceFeed),
            1 days,
            address(qiPriceFeed),
            1 days,
            25 ether, // min eth
            1500 ether // max eth
        );
        for (uint i = 0; i < users.length; i++) {
            vm.prank(admin);
            qi.mint(users[i], 10000000000000000 ether); // mint qi
            vm.deal(users[i], 10000000000000000 ether); // mint eth
            vm.prank(users[i]);
            qi.approve(address(ignite), type(uint256).max);
        }
        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_WITHDRAW"), admin);
        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_RELEASE_LOCKED_TOKENS"), admin);

        vm.prank(admin);
        ignite.addPaymentToken(address(qi), address(qiPriceFeed), 1 days);
        durations.push(VALIDATION_DURATION_TWO_WEEKS);
        durations.push(VALIDATION_DURATION_FOUR_WEEKS);
        durations.push(VALIDATION_DURATION_EIGHT_WEEKS);
        durations.push(VALIDATION_DURATION_TWELVE_WEEKS);
        // register_With_Erc20_Fee(0,45,0);
        // echidna_check_qi_balance();
        // revert();
    }
    
 
}
