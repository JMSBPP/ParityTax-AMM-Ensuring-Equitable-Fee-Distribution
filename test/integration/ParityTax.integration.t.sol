// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {IParityTaxHook} from "../../src/interfaces/IParityTaxHook.sol";
import {ILPOracle} from "../../src/interfaces/ILPOracle.sol";
import {IFiscalPolicy} from "../../src/interfaces/IFiscalPolicy.sol";


import {FiscalListeningPost} from "../../src/FiscalListeningPost.sol";


import {IPLPResolver} from "../../src/interfaces/IPLPResolver.sol";
import {IJITResolver} from "../../src/interfaces/IJITResolver.sol";

import {IParityTaxRouter} from "../../src/interfaces/IParityTaxRouter.sol";

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";

import  "./sepolia/SepoliaContracts.sol";

import "@uniswap/v4-core/test/utils/Deployers.sol"; 

import "../helpers/LiquidityResolversSetUp.sol";

// Add missing constants
uint160 constant MIN_PRICE_LIMIT = 4295128739 + 1; // TickMath.MIN_SQRT_PRICE + 1
uint160 constant MAX_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342 - 1; // TickMath.MAX_SQRT_PRICE - 1

contract ParityTaxTestIntegration is Test ,Deployers, PosmTestSetup{
    IParityTaxHook parityTaxHook;
    ILPOracle lpOracle;
    IFiscalPolicy fiscalPolicy;
    IPLPResolver plpResolver;
    IJITResolver jitResolver;
    IParityTaxRouter parityTaxRouter;

    FiscalListeningPost fiscalPolicyReactive;



    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
    address deployerAddress = vm.addr(deployerPrivateKey);
       
    PoolKey noHookKey;
    

    function setUp() public{
        parityTaxHook = IParityTaxHook(
            DevOpsTools.get_most_recent_deployment(
                "ParityTaxHook",
                block.chainid
            )
        );

        lpOracle = ILPOracle(
            DevOpsTools.get_most_recent_deployment(
                "MockLPOracle",
                block.chainid
            )
        );

        fiscalPolicy = IFiscalPolicy(
            DevOpsTools.get_most_recent_deployment(
                "UniformFiscalPolicy",
                block.chainid
            )
        );

        plpResolver = IPLPResolver(
            DevOpsTools.get_most_recent_deployment(
                "MockPLPResolver",
                block.chainid
            )
        );

        jitResolver = IJITResolver(
            DevOpsTools.get_most_recent_deployment(
                "MockJITResolver",
                block.chainid
            )
        );

        parityTaxRouter = IParityTaxRouter(
            DevOpsTools.get_most_recent_deployment(
                "ParityTaxRouter",
                block.chainid
            )
        );

        // fiscalPolicyReactive = FiscalListeningPost(
 
        //     payable(
        //         DevOpsTools.get_most_recent_deployment(
        //             "FiscalListeningPost",
                    
        //         )
        //     )
        // );
        // Deploy currencies first - this mints tokens to the test contract
        
        // Fund and approve resolvers using broadcast
        vm.startBroadcast(deployerPrivateKey);
        MockERC20[] memory tokens;
        tokens = new MockERC20[](2);
        for (uint8 i = 0; i < 2; i++) {
            tokens[i] = new MockERC20("TEST", "TEST", 18);
            tokens[i].mint(deployerAddress, 2 ** 255);
        }

        (currency0, currency1) = SortTokens.sort(tokens[0], tokens[1]);
        
        // Set up resolvers and policies (these don't need broadcast)
        parityTaxHook.setLiquidityResolvers(
            plpResolver, 
            jitResolver
        );

        parityTaxHook.setFiscalPolicy(
            fiscalPolicy
        );
        // Initialize pool
       
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: Constants.FEE_MEDIUM,
            tickSpacing: int24(60),
            hooks: IHooks(address(parityTaxHook))
        });
        noHookKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: Constants.FEE_MEDIUM,
            tickSpacing: int24(60),
            hooks: IHooks(address(0x00))
        });


        SEPOLIA_POOL_MANAGER.initialize(key, SQRT_PRICE_1_1);
        SEPOLIA_POOL_MANAGER.initialize(noHookKey, SQRT_PRICE_1_1);

    
        // Fund resolvers - transfer directly from test contract to resolvers
        IERC20(Currency.unwrap(currency0)).transfer(address(jitResolver), 1e18);
        IERC20(Currency.unwrap(currency1)).transfer(address(jitResolver), 1e18);
        IERC20(Currency.unwrap(currency0)).transfer(address(plpResolver), 1e18);
        IERC20(Currency.unwrap(currency1)).transfer(address(plpResolver), 1e18);
        
        
        // Approve resolvers for tokens
        IERC20(Currency.unwrap(currency0)).approve(address(jitResolver), type(uint256).max);
        IERC20(Currency.unwrap(currency1)).approve(address(jitResolver), type(uint256).max);
        IERC20(Currency.unwrap(currency0)).approve(address(plpResolver), type(uint256).max);
        IERC20(Currency.unwrap(currency1)).approve(address(plpResolver), type(uint256).max);
        
        // Approve position manager for resolvers
        IERC20(Currency.unwrap(currency0)).approve(address(SEPOLIA_POSITION_MANAGER), type(uint256).max);
        IERC20(Currency.unwrap(currency1)).approve(address(SEPOLIA_POSITION_MANAGER), type(uint256).max);
        
        // Approve parity tax router
        IERC20(Currency.unwrap(key.currency0)).approve(
            address(parityTaxRouter),
            IERC20(Currency.unwrap(key.currency0)).balanceOf(deployerAddress)
        );
        IERC20(Currency.unwrap(key.currency1)).approve(
            address(parityTaxRouter),
            IERC20(Currency.unwrap(key.currency1)).balanceOf(deployerAddress)
        );

        vm.stopBroadcast();

    }


    function test__JIT__fulfills_ZeroForOneSwap() public {
        console2.log("//========================BEFORE SWAP STATE =========================");
        
        // Check initial balances
        uint256 deployerBalance0Before = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 deployerBalance1Before = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("Deployer balance currency0 before:", deployerBalance0Before);
        console2.log("Deployer balance currency1 before:", deployerBalance1Before);
        
        // Check resolver balances
        uint256 jitBalance0Before = IERC20(Currency.unwrap(currency0)).balanceOf(address(jitResolver));
        uint256 jitBalance1Before = IERC20(Currency.unwrap(currency1)).balanceOf(address(jitResolver));
        console2.log("JIT Resolver balance currency0 before:", jitBalance0Before);
        console2.log("JIT Resolver balance currency1 before:", jitBalance1Before);

        console2.log("//==============================SWAP===============================");
        
        SwapParams memory largeSwapParams = SwapParams({
            zeroForOne: true,
            amountSpecified: -1e15, // exact input
            sqrtPriceLimitX96: MIN_PRICE_LIMIT 
        });
        
        console2.log("Executing swap with amount:", uint256(1e15));
        vm.startBroadcast(deployerPrivateKey);
       
        

        (BalanceDelta hookDelta) = parityTaxRouter.swap(
            key, // Pool with Hook
            largeSwapParams
        );

        vm.stopBroadcast();
        
        console2.log("//=======================AFTER SWAP STATE================================");
        
        // Check final balances
        uint256 deployerBalance0After = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 deployerBalance1After = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("Deployer balance currency0 after:", deployerBalance0After);
        console2.log("Deployer balance currency1 after:", deployerBalance1After);
        
        // Check resolver balances after swap
        uint256 jitBalance0After = IERC20(Currency.unwrap(currency0)).balanceOf(address(jitResolver));
        uint256 jitBalance1After = IERC20(Currency.unwrap(currency1)).balanceOf(address(jitResolver));
        console2.log("JIT Resolver balance currency0 after:", jitBalance0After);
        console2.log("JIT Resolver balance currency1 after:", jitBalance1After);
        
        // Verify balance changes match expected delta
        assertEq(deployerBalance0Before - deployerBalance0After, uint256(-int256(hookDelta.amount0())));
        assertEq(deployerBalance1After - deployerBalance1Before, uint256(int256(hookDelta.amount1())));
        
        console2.log("Swap delta amount0:", int256(hookDelta.amount0()));
        console2.log("Swap delta amount1:", int256(hookDelta.amount1()));
        
        console2.log("//======================================================================");
    }







}