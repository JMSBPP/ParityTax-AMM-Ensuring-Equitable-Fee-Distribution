// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ParityTaxHook} from "../src/ParityTaxHook.sol";


import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


import {HookTest} from "@uniswap-hooks/test/utils/HookTest.sol";
import {BalanceDeltaAssertions} from "@uniswap-hooks/test/utils/BalanceDeltaAssertions.sol";
import {PosmTestSetup} from "@uniswap/v4-periphery/test/shared/PosmTestSetup.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {MockJITOperator} from "./mocks/MockJITOperator.sol";
import {MockPLPOperator} from "./mocks/MockPLPOperator.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {LumpSumTaxController} from "./mocks/LumpSumTaxController.sol";




contract ParityTaxHookTest is PosmTestSetup, HookTest, BalanceDeltaAssertions{
    
    PoolKey noHookKey;    
    ParityTaxHook parityTax;


    
    
    MockJITOperator jitOperator;
    MockPLPOperator plpOperator;
    LumpSumTaxController taxController;
    V4Quoter v4Quoter;


    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        deployPosm(manager);
        jitOperator = new MockJITOperator(
            address(lpm)
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

        parityTax = ParityTaxHook(
            address(
                uint160(
                    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG |
                    Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
                    Hooks.AFTER_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG | 
                    Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG
                )

            )
            
        );
        deployCodeTo(
            "src/ParityTaxHook.sol:ParityTax",
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
            SQRT_PRICE_1_2
        );

        (noHookKey, ) = initPool(
            currency0,
            currency1,
            IHooks(
                address(0x00)
            ),
            Constants.FEE_MEDIUM,
            SQRT_PRICE_1_2
        );


        vm.label(Currency.unwrap(currency0), "currency0");
        vm.label(Currency.unwrap(currency1), "currency1");

    }

    function test_noSwaps() public {
        // add liquidity
        modifyPoolLiquidity(key, -600, 600, 1e18, 0);
        modifyPoolLiquidity(noHookKey, -600, 600, 1e18, 0);

        // remove liquidity
        BalanceDelta hookDelta = modifyPoolLiquidity(key, -600, 600, -1e17, 0);
        BalanceDelta noHookDelta = modifyPoolLiquidity(noHookKey, -600, 600, -1e17, 0);

        assertEq(hookDelta, noHookDelta, "No swaps: equivalent behavior");
    }


}




