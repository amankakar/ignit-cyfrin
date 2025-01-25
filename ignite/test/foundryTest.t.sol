// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Ignite} from "../src/Ignite.sol";
import {PriceFeed} from "./contracts/PriceFeed.sol";
import {StakedAvax} from "./contracts/StakedAvax.sol";
import {FaucetToken} from "./contracts/FaucetToken.sol";
import {Test} from "forge-std/Test.sol";
import  "forge-std/console.sol";
import {IgniteStorage} from "../src/IgniteStorage.sol";

contract MyTest is Test {
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
    address public constant FEE_RECIPIENT =
        0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address public constant SLASHED_TOKEN_RECIPIENT =
        0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    uint public gostMinimumContractBalance;
    uint256[] public durations;
    uint public constant VALIDATION_DURATION_TWO_WEEKS = 86400 * 7 * 2;
    uint public constant VALIDATION_DURATION_FOUR_WEEKS = 86400 * 7 * 4;
    uint public constant VALIDATION_DURATION_EIGHT_WEEKS = 86400 * 7 * 8;
    uint public constant VALIDATION_DURATION_TWELVE_WEEKS = 86400 * 7 * 12;
    uint[] public amountArr = [
        25 ether,
        50 ether,
        75 ether,
        100 ether,
        125 ether,
        150 ether,
        175 ether,
        200 ether,
        225 ether,
        250 ether,
        275 ether,
        300 ether,
        325 ether,
        350 ether,
        375 ether,
        400 ether,
        425 ether,
        450 ether,
        475 ether,
        500 ether
    ];

    string[] public nodeIds;
    string[] public failRegistrationIndices;
    uint[] public successRegistrationIndices;
    bool public releaseLockTokenFailedCalled;
    bool public releaseLockTokenSuccessCalled;
    bool public releaseLockTokenSlashedCalled;

    uint public avaxFee;
    uint public avaxSlash;
    uint public tokenFee;
    uint public tokenSlash;
    bool public isRegisteredCalled;
    function boundValue(
        uint256 value,
        uint256 min,
        uint256 max
    ) public pure returns (uint256) {
        return min + (value % (max - min));
    }

    function setUp() external {
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
            vm.deal(admin, 1000000000000000000000000000000000 ether); // mint eth
        for (uint i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            qi.mint(100000000000000000000000000000000 ether); // mint qi
            vm.deal(users[i], 1000000000000000000000000000000000 ether); // mint eth
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

    function register_with_stake(
        uint256 userIndex,
        uint256 amountIndex,
        uint256 nodeId,
        uint validationDurationIndex
    ) public {
        amountIndex = boundValue(amountIndex, 0, amountArr.length);
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        ); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];
        // uint registrationFee = ignite.getRegistrationFee(validationDuration);

        // gostMinimumContractBalance += registrationFee;

        address user = users[userIndex];
        uint amount = amountArr[amountIndex];
        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint qiAmount = (uint(avaxPrice) * (2000e18 - amount)) /
            uint(qiPrice) /
            10;
        totalQIStaked += qiAmount;
        totalEthStaked += amount;
        vm.prank(user);
        ignite.registerWithStake{value: amount}(
            string(abi.encodePacked("NodeID-", nodeId)),
            blsPoP,
            validationDuration
        );
        nodeIds.push(string(abi.encodePacked("NodeID-", nodeId)));
        isRegisteredCalled = true;
    }
    function register_with_erc20_fee(
        uint256 userIndex,
        uint256 nodeId,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        ); // 2-12 weeks
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint registrationFee = ignite.getRegistrationFee(validationDuration);

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        uint tokenAmount = (uint(avaxPrice) * registrationFee) /
            uint(qiPrice) /
            10 ** (18 - qi.decimals());
        uint amount = (tokenAmount * qiPriceMultiplier) / 10_000;
        totalQIStaked += amount;
        vm.prank(user);
        ignite.registerWithErc20Fee(
            address(qi),
            string(abi.encodePacked("NodeID-", nodeId)),
            blsPoP,
            validationDuration
        );
        nodeIds.push(string(abi.encodePacked("NodeID-", nodeId)));
        isRegisteredCalled = true;
    }

    function register_with_prevalidated_qiStake(
        uint256 userIndex,
        uint256 nodeId,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        );
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];

        vm.prank(admin);
        ignite.grantRole(
            keccak256("ROLE_REGISTER_WITH_FLEXIBLE_PRICE_CHECK"),
            user
        );

        (, int avaxPrice, , , ) = avaxPriceFeed.latestRoundData();
        (, int qiPrice, , , ) = qiPriceFeed.latestRoundData();
        // 200 AVAX + 1 AVAX fee = 201e18
        uint expectedQiAmount = (uint(avaxPrice) * 201e18) / uint(qiPrice);

        uint qiAmount = (expectedQiAmount * 9) / 10;

        totalQIStaked += qiAmount;
        vm.prank(user);
        ignite.registerWithPrevalidatedQiStake(
            address(user),
            string(abi.encodePacked("NodeID-", nodeId)),
            blsPoP,
            validationDuration,
            qiAmount
        );
        nodeIds.push(string(abi.encodePacked("NodeID-", nodeId)));
        isRegisteredCalled = true;
    }
    function register_without_collateral(
        uint256 userIndex,
        uint256 nodeId,
        uint validationDurationIndex
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length + 1
        );
        uint256[5] memory _durations = [
            durations[0],
            durations[1],
            durations[2],
            durations[3],
            86400 * 365
        ];
        uint validationDuration = _durations[validationDurationIndex];

        address user = users[userIndex];

        vm.prank(admin);
        ignite.grantRole(keccak256("ROLE_REGISTER_WITHOUT_COLLATERAL"), user);

        vm.prank(user);
        ignite.registerWithoutCollateral(
            string(abi.encodePacked("NodeID-", nodeId)),
            blsPoP,
            validationDuration
        );
        nodeIds.push(string(abi.encodePacked("NodeID-", nodeId)));
    }

    function register_with_avax_fee(
        uint256 userIndex,
        uint validationDurationIndex,
        uint256 nodeId
    ) public {
        userIndex = boundValue(userIndex, 0, users.length);
        validationDurationIndex = boundValue(
            validationDurationIndex,
            0,
            durations.length
        );
        uint validationDuration = durations[validationDurationIndex];

        address user = users[userIndex];
        uint amount = ignite.getRegistrationFee(validationDuration);
        gostMinimumContractBalance += amount;
        totalEthStaked += amount;

        vm.prank(user);
        ignite.registerWithAvaxFee{value: amount}(
            string(abi.encodePacked("NodeID-", nodeId)),
            blsPoP,
            validationDuration
        );
        nodeIds.push(string(abi.encodePacked("NodeID-", nodeId)));
        isRegisteredCalled = true;
    }

    function withdraw_eth(uint amount) public {
        uint minBal = ignite.minimumContractBalance();
        amount = boundValue(
            amount,
            minBal + 1,
            address(ignite).balance - minBal + 1
        );

        totalEthStaked -= amount;
        vm.prank(admin);
        ignite.withdraw(amount);
    }
    function release_locked_tokens_failed(uint256 nodeIdIndex) public {
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            ,
            ,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        if (!withdrawable) {
            if (feePaid) {
                vm.prank(admin);
                ignite.releaseLockedTokens{value: 0}(
                    nodeId,
                    true // bool failed
                );
            } else {
                if (tokenDeposits.avaxAmount > 0 && tokenDeposits.tokenAmount > 0){

                    failRegistrationIndices.push(nodeId);
                    console.log("failRegistrationIndices.length",failRegistrationIndices.length);
                    console.log("index pushed " , registrationIndex);

                }
                totalEthStaked += tokenDeposits.avaxAmount;
                gostMinimumContractBalance += tokenDeposits.avaxAmount;

                vm.prank(admin);
                ignite.releaseLockedTokens{value: tokenDeposits.avaxAmount}(
                    nodeId,
                    true // bool failed
                );
            }
        }
        releaseLockTokenFailedCalled = true;
    }

    function release_locked_tokens_success(uint256 nodeIdIndex) public {
        if (!isRegisteredCalled) return;
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            ,
            ,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        if (!withdrawable) {
            if (feePaid) {
                if (tokenDeposits.avaxAmount > 0) {
                    successRegistrationIndices.push(registrationIndex);
                    totalEthStaked -= tokenDeposits.avaxAmount;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                    avaxFee += tokenDeposits.avaxAmount;
                    gostMinimumContractBalance -= tokenDeposits.avaxAmount;
                } else {
                    successRegistrationIndices.push(registrationIndex);
                    totalQIStaked -= tokenDeposits.tokenAmount;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                    tokenFee += tokenDeposits.tokenAmount;
                }
            } else {
                if (ignite.qiRewardEligibilityByNodeId(nodeId)) {
                    uint fee = tokenDeposits.tokenAmount / 201;

                    totalQIStaked -= fee;

                    tokenFee += fee;

                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: 0}(
                        nodeId,
                        false // bool failed
                    );
                } else {
                    uint msgValue = tokenDeposits.avaxAmount + 10;
                    totalEthStaked += msgValue;
                    gostMinimumContractBalance += msgValue;
                    vm.prank(admin);
                    ignite.releaseLockedTokens{value: msgValue}(
                        nodeId,
                        false // bool failed
                    );
                }
            }
        }
        releaseLockTokenSuccessCalled = true;
    }

    function release_locked_tokens_slash(uint256 nodeIdIndex) public {
        nodeIdIndex = boundValue(nodeIdIndex, 0, nodeIds.length);
        string memory nodeId = nodeIds[nodeIdIndex];
        uint registrationIndex = ignite.registrationIndicesByNodeId(nodeId);
        (
            ,
            ,
            ,
            bool feePaid,
            IgniteStorage.TokenDepositDetails memory tokenDeposits,
            ,
            uint qiSlashPercentage,
            uint avaxSlashPercentage,
            ,
            bool withdrawable
        ) = ignite.registrations(registrationIndex);

        uint msgValue = tokenDeposits.avaxAmount;
        if (!withdrawable) {
            if (!feePaid && msgValue != 0) {
                vm.prank(admin);
                ignite.releaseLockedTokens{value: msgValue}(
                    nodeId,
                    false // bool failed
                );

                if (qiSlashPercentage > 0) {
                    uint qiSlashAmount = (tokenDeposits.tokenAmount *
                        qiSlashPercentage) / 10_000;

                    totalQIStaked -= qiSlashAmount;
                }

                if (avaxSlashPercentage > 0) {
                    uint avaxSlashAmount = (tokenDeposits.avaxAmount *
                        avaxSlashPercentage) / 10_000;

                    gostMinimumContractBalance += msgValue - avaxSlashAmount;

                    totalEthStaked -= avaxSlashAmount;
                } else {
                    gostMinimumContractBalance += msgValue;
                }
            }
        }
        releaseLockTokenSlashedCalled = true;
    }






    function test_call_sequence_eth() public{
    //   *wait* Time delay: 2339943 seconds Block delay: 214168
    vm.warp(block.timestamp+2339943);
    register_with_avax_fee(23800931640981862246272855095199168797465484570217772509906087200776201984824,49999999999999999999,40452286043366250835527447481768949284813338991617241741765092741729749528631);
    vm.warp(block.timestamp+1003569);
    // *wait* Time delay: 1003569 seconds Block delay: 5889
    register_without_collateral(115792089237316195423570985008687907853269984665640564039457584007913129639932,83586453273967205365305483547111057541932601632404957870743428521042903560899,15000000000000000000);
    register_with_avax_fee(20420479259341404712880216297933415342237411048843792535910610419262418259320,364,63037373784252482332977258390710441587434745557131538400600434875942230339); 
    vm.warp(block.timestamp+637072);
    // *wait* Time delay: 637072 seconds Block delay: 14369
    release_locked_tokens_slash(18381818903501417271993037180782586624320017583168633123491174667116302679771);
assertEq(address(ignite).balance, totalEthStaked);
assertEq(address(SLASHED_TOKEN_RECIPIENT).balance ,avaxSlash);
 assertEq(qi.balanceOf(SLASHED_TOKEN_RECIPIENT) ,tokenSlash);

    }
      function echidna_check_fail_registration_withdrawal() public view returns(bool){
        if(releaseLockTokenFailedCalled){
            for(uint i = 0; i < failRegistrationIndices.length; i++){
                uint registrationIndex = ignite.registrationIndicesByNodeId(failRegistrationIndices[i]);

                // console.log("-------failRegistrationIndices[i]",failRegistrationIndices[i]);
                (,,,,,,,,,bool withdrawable) = ignite.
                registrations(registrationIndex);
                    if(!withdrawable){
                        return false;
                    }   
            }
        }
        return true;
    }
    function test_call_sequence_slash() public{
        
    register_without_collateral(90793348850281496678072320409872830544682414578408269142394356939249042, 1437443316294098354833584440837003196499155786356999691924578140198683386056, 19752092795023871847753688518486364829031218708396609936401178172412537906) ;
register_with_prevalidated_qiStake(5105119814835423036487567069330023021291179814951192448432288748189120288252, 0, 18834950799826133674679561860959377891541967708779631289483411356347351894687);
register_with_stake(10966200542012969634211031576633892897321859707106703157960541085650787, 4385353717600810109332974968747091428581898330881677267013117767073, 1920377899237386249565612527936372468840264932211331914352590355686, 133866624528333825974145232731214727132651979223105125572269053) ;
release_locked_tokens_failed(4341276485053523731922015069182412891618619688854406941254744768412543416) ;
release_locked_tokens_failed(12285431668945874510626838611571498633450458003316214180068652652434354169947) ;
 console.log("failRegistrationIndices.length-1");
 console.log(failRegistrationIndices.length-1);
   console.log("ignite.getTotalRegistrations()");
   console.log(ignite.getTotalRegistrations());
assertTrue(echidna_check_fail_registration_withdrawal());
    }

    function _getRegistrationFee(uint validationDuration) internal view returns (uint) {
        if (validationDuration == VALIDATION_DURATION_TWO_WEEKS) {
            return 8e18;
        }

        if (validationDuration == VALIDATION_DURATION_FOUR_WEEKS) {
            return 15e18;
        }

        if (validationDuration == VALIDATION_DURATION_EIGHT_WEEKS) {
            return 28e18;
        }

        if (validationDuration == VALIDATION_DURATION_TWELVE_WEEKS) {
            return 40e18;
        }

    }



}
