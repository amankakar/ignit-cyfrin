// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {StakingContract} from "../../src/staking.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../../src/interfaces/IJoeRouter02.sol";
import "../../src/interfaces/IIgnite.sol";


abstract contract Setup is BaseSetup {
    // Store All the State variables here  , like mapping , users and contract instances
    address benqiAdmin;
    address zeeveSuperAdmin;
    address benqiSuperAdmin = benqiAdmin = address(0x23457643);
    address zeeveAdmin = zeeveSuperAdmin = address(0x234576);
    address admin = address(0x237643);

    address[] public users;

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

    address  public qiTokenAddress = 0xFFd31a26B7545243F430C0999d4BF11A93408a8C;
    address  public avaxPriceFeed = 0x7dF6058dd1069998571497b8E3c0Eb13A8cb6a59;
    address  public qiPriceFeed = 0xF3f62E241bC33EF00C731D257F945e8645396Ced;
    address public  zeeveWallet = 0x6Ce78374dFf46B660E274d0b10E29890Eeb0167b;
    address  public igniteSmartContract = 0xF1652dc03Ee76F7b22AFc7FF1cD539Cf20d545D5;
    address  public joeRouterAddress = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
    uint256  public initialStakingAmount = 1 ether; // 200 AVAX
    uint256  public initialHostingFee = 0.001 ether; // 1.4 AVAX
    address  public AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
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

    function setup() internal virtual override {
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
            1 days,
            1 days
        );
        ghost_acceptedTokens.add(AVAX);
        ghost_acceptedTokens.add(contractAddresses.qiToken);
        ghost_joeRouter = IJoeRouter02(joeRouterAddress);

        ghost_intermediaryToken = ghost_joeRouter.WAVAX();


        // stakingInstance.initialize(
        //     contractAddresses,
        //     benqiSuperAdmin,
        //     benqiAdmin,
        //     zeeveSuperAdmin,
        //     zeeveAdmin,
        //     initialStakingAmount,
        //     initialHostingFee,
        //     joeRouterAddress,
        //     1 days,
        //     1 days
        // );
    }

    // function isAcceptedTokens(address targetToken) public view returns(bool) {
    //     return ghost_acceptedTokens.contains(targetToken);
    // }
}
