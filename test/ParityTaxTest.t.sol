// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    ParityTaxHook,
    IPoolManager,
    PoolId,
    PoolIdLibrary,
    PoolKey,
    StateLibrary,
    IPositionManager
} from "../src/ParityTaxHook.sol";

import {PositionDescriptor} from "@uniswap/v4-periphery/src/PositionDescriptor.sol";
import {PositionManager} from "@uniswap/v4-periphery/src/PositionManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {
    BalanceDelta,
    BalanceDeltaLibrary
} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

import {
    SwapParams,
    ModifyLiquidityParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


import {HookTest} from "@uniswap-hooks/test/utils/HookTest.sol";
import {BalanceDeltaAssertions} from "@uniswap-hooks/test/utils/BalanceDeltaAssertions.sol";
import {
    PosmTestSetup,
    IWETH9,
    IAllowanceTransfer
} from "@uniswap/v4-periphery/test/shared/PosmTestSetup.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {MockJITOperator} from "./mocks/MockJITOperator.sol";
import {MockPLPOperator} from "./mocks/MockPLPOperator.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {LumpSumTaxController} from "./mocks/LumpSumTaxController.sol";
import {StateView} from "@uniswap/v4-periphery/src/lens/StateView.sol";

import {console2} from "forge-std/Test.sol";

// Add missing constants
uint160 constant MIN_PRICE_LIMIT = 4295128739 + 1; // TickMath.MIN_SQRT_PRICE + 1
uint160 constant MAX_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342 - 1; // TickMath.MAX_SQRT_PRICE - 1

contract ParityTaxHookTest is PosmTestSetup, HookTest, BalanceDeltaAssertions{
    using StateLibrary for IPoolManager;
    using BalanceDeltaLibrary for BalanceDelta;
    using PoolIdLibrary for PoolKey;
    PoolKey noHookKey;    
    ParityTaxHook parityTax;

    
    MockJITOperator jitOperator;
    MockPLPOperator plpOperator;
    LumpSumTaxController taxController;
    V4Quoter v4Quoter;
    StateView stateView;


    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        deployPosm(manager);


        jitOperator = new MockJITOperator(
            address(lpm),
            address(permit2)
        );
        
        plpOperator = new MockPLPOperator(
            manager
        );
        taxController = new LumpSumTaxController(
            plpOperator,
            jitOperator
        );
        v4Quoter = new V4Quoter(
            manager
        );

        stateView = new StateView(manager);

        parityTax = ParityTaxHook(
            address(
                uint160(
                    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG| 
                    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG | 
                    Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG | Hooks.BEFORE_SWAP_FLAG | 
                    Hooks.AFTER_SWAP_FLAG 
                )

            )
            
        );
        deployCodeTo(
            "ParityTaxHook.sol:ParityTaxHook",
            abi.encode(
                manager,
                address(v4Quoter),
                address(jitOperator),
                address(plpOperator),
                address(0x123),
                address(taxController)
            ),
            address(parityTax)
        );


        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(
                address(parityTax)
            ),
            Constants.FEE_MEDIUM,
            SQRT_PRICE_1_1
        );

        (noHookKey, ) = initPool(
            currency0,
            currency1,
            IHooks(
                address(0x00)
    ),
            Constants.FEE_MEDIUM,
            SQRT_PRICE_1_1
        );


        vm.label(Currency.unwrap(currency0), "currency0");
        vm.label(Currency.unwrap(currency1), "currency1");

    }

    function test__Unit__noSwapsEquivalentBehavior() public {
        // add liquidity
        modifyPoolLiquidity(key, -600, 600, 1e18, 0);
        modifyPoolLiquidity(noHookKey, -600, 600, 1e18, 0);

        // remove liquidity
        BalanceDelta hookDelta = modifyPoolLiquidity(key, -600, 600, -1e17, 0);
        BalanceDelta noHookDelta = modifyPoolLiquidity(noHookKey, -600, 600, -1e17, 0);
        console2.log("Permit 2 Address:", address(permit2));
        assertEq(hookDelta, noHookDelta, "No swaps: equivalent behavior");
    }               

    function test__Unit_JITSingleLP() public {
        
        
        //=============  beforeSwap PLP Liquidity ==========
        modifyPoolLiquidity(noHookKey, -600, 600, 1e18, 0);
        modifyPoolLiquidity(key, -600, 600, 1e18, 0);
        
        //==================LARGE SWAP===================
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: false, 
            settleUsingBurn: false  
        });

        SwapParams memory largeSwapParams = SwapParams({
            zeroForOne: true,
            amountSpecified: -1e15, // exact input
            sqrtPriceLimitX96: MIN_PRICE_LIMIT 
        });

        (BalanceDelta noHookDelta) = swapRouter.swap(
            noHookKey, 
            largeSwapParams, 
            testSettings, 
            Constants.ZERO_BYTES
        );
        console2.log("amount0 with no Hook:", noHookDelta.amount0());
        console2.log("amount1 with no Hook:", noHookDelta.amount1());
        
        (BalanceDelta hookDelta) = swapRouter.swap(
            key, // Pool with Hook
            largeSwapParams,
            testSettings,
            Constants.ZERO_BYTES
        );

        console2.log("amount0 with Hook:", hookDelta.amount0());
        console2.log("amount1 with Hook:", hookDelta.amount1());


    }





}

