// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../src/types/Shared.sol";

import {
    ParityTaxHook,
    PoolId,
    PoolIdLibrary,
    PoolKey,
    StateLibrary
} from "../src/ParityTaxHook.sol";

import {PositionDescriptor} from "@uniswap/v4-periphery/src/PositionDescriptor.sol";
import {PositionManager} from "@uniswap/v4-periphery/src/PositionManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

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



import {console2} from "forge-std/Test.sol";

import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";



import "./helpers/LiquidityResolversSetUp.sol";
import "./helpers/TaxControllerSetUp.sol";
// Add missing constants
uint160 constant MIN_PRICE_LIMIT = 4295128739 + 1; // TickMath.MIN_SQRT_PRICE + 1
uint160 constant MAX_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342 - 1; // TickMath.MAX_SQRT_PRICE - 1

contract ParityTaxHookTest is TaxControllerSetUp, LiquidityResolversSetUp, HookTest, BalanceDeltaAssertions{
    using StateLibrary for IPoolManager;
    using BalanceDeltaLibrary for BalanceDelta;
    using PoolIdLibrary for PoolKey;
    using Position for address;
    using PositionInfoLibrary for PositionInfo;
    using SafeCast for *;
    PoolKey noHookKey;    
    ParityTaxHook parityTaxHook;

    address alice = makeAddr("ALICE");
    address bob = makeAddr("BOB");



    function setUp() public {

        
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        deployAndApprovePosm(manager);
        deployAndApproveResolvers(manager,lpm);
        deployAndApproveTaxController(manager);


        
        fundResolvers();
        

        parityTaxHook = ParityTaxHook(
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
                lpm,
                jitResolver,
                plpResolver,
                parityTaxRouter,
                taxController,
                lpOracle
            ),
            address(parityTaxHook)
        );
        plpResolver.setParityTaxHook(parityTaxHook);



        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(
                address(parityTaxHook)
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

        seedBalance(alice);
        seedBalance(bob);
        approvePosmFor(alice);
        approvePosmFor(bob);

        vm.startPrank(alice);
        IERC20(Currency.unwrap(key.currency0)).approve(
            address(parityTaxRouter),
            IERC20(Currency.unwrap(key.currency0)).balanceOf(alice)
        );
        IERC20(Currency.unwrap(key.currency1)).approve(
            address(parityTaxRouter),
            IERC20(Currency.unwrap(key.currency1)).balanceOf(alice)
        );
        vm.stopPrank();


        vm.startPrank(bob);
        IERC20(Currency.unwrap(key.currency0)).approve(
            address(swapRouter),
            IERC20(Currency.unwrap(key.currency0)).balanceOf(bob)
        );
        IERC20(Currency.unwrap(key.currency1)).approve(
            address(swapRouter),
            IERC20(Currency.unwrap(key.currency1)).balanceOf(bob)
        );
        vm.stopPrank();





    }

    function test__NoSwaps__EquivalentBehavior() public {
        // add liquidity
        modifyPoolLiquidity(key, -600, 600, 1e18, 0);
        modifyPoolLiquidity(noHookKey, -600, 600, 1e18, 0);

        // remove liquidity
        BalanceDelta hookDelta = modifyPoolLiquidity(key, -600, 600, -1e17, 0);
        BalanceDelta noHookDelta = modifyPoolLiquidity(noHookKey, -600, 600, -1e17, 0);
        assertEq(hookDelta, noHookDelta, "No swaps: equivalent behavior");
    }               

    function test__JIT_Fulfills__ZeroForOneSwap() public {

        //=============  beforeSwap PLP Liquidity ==========
        
        modifyPoolLiquidity(noHookKey, -600, 600, 1e18, 0);
        modifyPoolLiquidity(key, -600, 600, 1e18, 0);
        
        //================================================
        // NOTE: We need to make sure the liquidity was added on both cases
        console2.log("//========================BEFORE SWAP STATE =========================");
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency0)).balanceOf(alice));
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency1)).balanceOf(alice));
        console2.log("Alice Has Starting Balance Of Both Currencies", STARTING_USER_BALANCE);
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency0)).balanceOf(bob));
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency1)).balanceOf(bob));
        console2.log("Bob Has Starting Balance Of Both Currencies", STARTING_USER_BALANCE);
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency0)).balanceOf(address(jitResolver)));
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency1)).balanceOf(address(jitResolver)));
        
        console2.log("JIT Resolver funds are the Starting Balance for Both Currencies", STARTING_USER_BALANCE);
        
        console2.log("//==================================================================");
        console2.log("//==============================SWAP===============================");
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: false, 
            settleUsingBurn: false  
        });

        console2.log("Bob Is doing swap in Hook less Pool whereas Alice is doing swap in Hooked Pool");
        
        SwapParams memory largeSwapParams = SwapParams({
            zeroForOne: true,
            amountSpecified: -1e15, // exact input
            sqrtPriceLimitX96: MIN_PRICE_LIMIT 
        });
        console2.log(
            "Swapping Token 0 for One Specifying input",
            largeSwapParams.zeroForOne && largeSwapParams.amountSpecified < 0
        );

        console2.log(
            "Currency 0 deposit for swapper",
            uint256(1e15)
        );

        vm.startPrank(bob);
        
        
        (BalanceDelta noHookDelta) = swapRouter.swap(
            noHookKey, 
            largeSwapParams, 
            testSettings, 
            Constants.ZERO_BYTES
        );

        vm.stopPrank();

        vm.startPrank(alice);


        (BalanceDelta hookDelta) = parityTaxRouter.swap(
            key, // Pool with Hook
            largeSwapParams
        );

        vm.stopPrank();
        console2.log("//======================================================================");
        console2.log("//=======================AFTER SWAP STATE================================");
        console2.log("After Swap Bob has a decreased balance on Currency 0", IERC20(Currency.unwrap(key.currency0)).balanceOf(bob));
        assertEq(
            STARTING_USER_BALANCE - uint256(-int256(noHookDelta.amount0())),
            IERC20(Currency.unwrap(key.currency0)).balanceOf(bob)
        );
        console2.log("After Swap Bob Has a increased balance on Currency 1", IERC20(Currency.unwrap(key.currency1)).balanceOf(bob));
        
        assertEq(
            STARTING_USER_BALANCE + uint256(int256(noHookDelta.amount1())),
            IERC20(Currency.unwrap(key.currency1)).balanceOf(bob)
        );

        console2.log("After Swap ALice has a decreased balance on Currency 0", IERC20(Currency.unwrap(key.currency0)).balanceOf(alice));
        assertEq(
            STARTING_USER_BALANCE - uint256(-int256(hookDelta.amount0())),
            IERC20(Currency.unwrap(key.currency0)).balanceOf(alice)
        );
        console2.log("After Swap Alice Has a increased balance on Currency 1", IERC20(Currency.unwrap(key.currency1)).balanceOf(alice));
        
        assertEq(
            STARTING_USER_BALANCE + uint256(int256(hookDelta.amount1())),
            IERC20(Currency.unwrap(key.currency1)).balanceOf(alice)
        );

        console2.log("The liquidity Resolver has earned swap fees to enable ALice Trade:");
        console2.log("After Swap JIT Resolver balance on Currency 0:",IERC20(Currency.unwrap(key.currency0)).balanceOf(address(jitResolver)));
        console2.log("After Swap JIT Resolver balance on Currency 1:",IERC20(Currency.unwrap(key.currency1)).balanceOf(address(jitResolver)));
        assertGt(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency1)).balanceOf(address(jitResolver)));
        console2.log("The cummulated Fees by the PLP on the Hookless Pool Are");


        console2.log("//======================================================================");
        






    }





}

