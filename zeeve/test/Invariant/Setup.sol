// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {StakingContract} from "../../src/staking.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../../src/interfaces/IJoeRouter02.sol";
import "../../src/interfaces/IIgnite.sol";
import {MockToken} from "./utils/MockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract Setup is BaseSetup {
    // Store All the State variables here  , like mapping , users and contract instances
    address benqiAdmin;
    address zeeveSuperAdmin;
    address benqiSuperAdmin = benqiAdmin = address(0x23457643);
    address zeeveAdmin = zeeveSuperAdmin = address(0x234576);
    address admin = address(0x237643);

    address[] public users;
    address alice = address(0x12);
    address bob = address(0x121);
    address cartor = address(0x122);

    StakingContract stakingInstance;

    IERC20Upgradeable public ghost_qiToken;
    IIgnite public ghost_igniteContract;

    address public ghost_zeeveWallet;
    IJoeRouter02 public ghost_joeRouter;
    address public ghost_intermediaryToken;
    // Configuration variables
    uint256 public ghost_avaxStakeAmount;
    uint256 public ghost_hostingFeeAvax;
    uint256 public ghost_slippage;
    uint256 public minSlippage;
    uint256 public ghost_maxSlippage;
    uint256 public ghost_refundPeriod;
    uint256 ghost_zeeveWallet_fee;
    uint256 ghost_staking_eth_bal=0;
    uint256 ghost_Qi_deposits =0;
    mapping (address users => uint256 qiDeposits) public usersQiDepsoits;
    mapping (address users => uint256 EthFee) public usersETHFee;
    mapping (address users => uint256 lastIndexes) public userRecordIndexes;


    address  public qiTokenAddress = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5; //0xFFd31a26B7545243F430C0999d4BF11A93408a8C;
    address  public avaxPriceFeed = 0x0A77230d17318075983913bC2145DB16C7366156;//0x7dF6058dd1069998571497b8E3c0Eb13A8cb6a59;
    address  public qiPriceFeed = 0x36E039e6391A5E7A7267650979fdf613f659be5D;//0xF3f62E241bC33EF00C731D257F945e8645396Ced;
    address public  zeeveWallet = 0x6Ce78374dFf46B660E274d0b10E29890Eeb0167b;
    address  public igniteSmartContract = 0xB71a820d80189073F69498010cb67bDDAe050633;//0xF1652dc03Ee76F7b22AFc7FF1cD539Cf20d545D5;
    address  public joeRouterAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;//0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
    uint256  public initialStakingAmount = 1 ether; // 200 AVAX
    uint256  public initialHostingFee = 0.001 ether; // 1.4 AVAX
    address  public AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256[] public durations;
    uint public constant VALIDATION_DURATION_TWO_WEEKS = 86400 * 7 * 2;
    uint public constant VALIDATION_DURATION_FOUR_WEEKS = 86400 * 7 * 4;
    uint public constant VALIDATION_DURATION_EIGHT_WEEKS = 86400 * 7 * 8;
    uint public constant VALIDATION_DURATION_TWELVE_WEEKS = 86400 * 7 * 12;
    uint public constant VALIDATION_DURATION_ONE_YEAR = 86400 * 365;

        bytes public blsKey =
        hex"8d609cdd38ffc9ad01c91d1ae4fccb8cd6c75a6ad33a401da42283b0c3b59bbaf5abc172335ea4d9c31baa936818f0ab";

    bytes public blsSignature =
        hex"8c12c805e7dfe4bfe38be44685ee852d931d73b3c0820a1343d731909120cee4895f9b60990520a90d06a031a42e0f8616d415b543408c24be0da90d5e7fa8242f4fd32dadf34c790996ca474dbdbcd763f82c53880db19fd3b30d13cee278b4";

    bytes public blsPoP = abi.encodePacked(blsKey, blsSignature);


    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Storage for accepted tokens and price feeds
    EnumerableSetUpgradeable.AddressSet private ghost_acceptedTokens;
    // mapping(address => AggregatorV3Interface) public ghost_priceFeeds;
    mapping(address => uint256) public ghost_maxPriceAges;

    struct ContractAddresses {
        address qiToken;
        address avaxPriceFeed;
        address qiPriceFeed;
        address zeeveWallet;
        address igniteContract;
    }

    // state variable to track function calls
    bool isStakeETHCalled;
    bool isStakeERC20Called;


    event Logs1(string);
    event Logs(uint);

    function setup() internal virtual override {
    uint256 Id = vm.createFork("https://api.avax.network/ext/bc/C/rpc"); // Fork at block 18,000,000        
    users.push(alice);
    vm.selectFork(Id);
    vm.warp(1737553949+ 10 days);
        users.push(bob);
        users.push(cartor);

        durations.push(VALIDATION_DURATION_TWO_WEEKS);
        durations.push(VALIDATION_DURATION_FOUR_WEEKS);
        durations.push(VALIDATION_DURATION_EIGHT_WEEKS);
        durations.push(VALIDATION_DURATION_TWELVE_WEEKS);
        durations.push(VALIDATION_DURATION_ONE_YEAR);

        // Add All the things here which we need to setup our fuzz suite
        stakingInstance = new StakingContract();
        
        StakingContract.ContractAddresses memory contractAddresses = StakingContract.ContractAddresses({
            qiToken: qiTokenAddress,
            avaxPriceFeed: avaxPriceFeed,
            qiPriceFeed: qiPriceFeed,
            zeeveWallet: zeeveWallet,
            igniteContract: igniteSmartContract
        });

            stakingInstance.initialize(
            contractAddresses,
            benqiSuperAdmin,
            benqiAdmin,
            zeeveSuperAdmin,
            zeeveAdmin,
            initialStakingAmount,
            initialHostingFee,
            joeRouterAddress,
            30 days,
            30 days
        );
        ghost_acceptedTokens.add(AVAX);
        ghost_acceptedTokens.add(contractAddresses.qiToken);
        ghost_joeRouter = IJoeRouter02(joeRouterAddress);
        ghost_avaxStakeAmount = initialStakingAmount;
        ghost_intermediaryToken = ghost_joeRouter.WAVAX();
MockToken qi = MockToken(qiTokenAddress);
        for (uint i = 0; i < users.length; i++) {
            vm.prank(0x4aeFa39caEAdD662aE31ab0CE7c8C2c9c0a013E8);
            qi.transfer(users[i], 10000 ether); // mint qi
            vm.deal(users[i], 10000000000000000 ether); // mint eth
            vm.prank(users[i]);
            qi.approve(address(stakingInstance), type(uint256).max);
        }
        vm.deal(benqiAdmin , 1 ether);
        vm.deal(zeeveSuperAdmin , 1 ether);

// stake_with_avax(1);
    }

         


function clampLte(uint256 a, uint256 b) internal pure returns (uint8) {
        if (!(a <= b)) {
            uint256 value = a % (b + 1);
            return uint8(value);
        }
        return uint8(a);
    }

    function boundValue(uint256 value, uint256 min, uint256 max) public pure returns (uint256) {
        return min + (value % (max - min));
    }


    function _getRegistrationFee(uint validationDuration) internal pure returns (uint) {
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

        revert("Invalid validation duration");
    }
    function isAcceptedTokens(address targetToken) public view returns(bool) {
        return ghost_acceptedTokens.contains(targetToken);
    }
}
