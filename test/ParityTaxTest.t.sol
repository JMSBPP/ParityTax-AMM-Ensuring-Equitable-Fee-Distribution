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

import {ParityTaxExtt} from "../src/ParityTaxExtt.sol";

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
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IParityTaxRouter} from "../src/interfaces/IParityTaxRouter.sol";


import "./helpers/LiquidityResolversSetUp.sol";
import "./helpers/FiscalPolicySetUp.sol";

// Add missing constants
uint160 constant MIN_PRICE_LIMIT = 4295128739 + 1; // TickMath.MIN_SQRT_PRICE + 1
uint160 constant MAX_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342 - 1; // TickMath.MAX_SQRT_PRICE - 1

contract ParityTaxHookTest is FiscalPolicySetUp, LiquidityResolversSetUp, HookTest, BalanceDeltaAssertions{
    using StateLibrary for IPoolManager;
    using BalanceDeltaLibrary for BalanceDelta;
    using PoolIdLibrary for PoolKey;
    using Position for address;
    using PositionInfoLibrary for PositionInfo;
    using SafeCast for *;
    PoolKey noHookKey;    
    ParityTaxHook parityTaxHook;
    ParityTaxExtt parityTaxExtt;

    address alice = makeAddr("ALICE");
    address bob = makeAddr("BOB");



    function setUp() public {

        
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        deployAndApprovePosm(manager);
        
        // Deploy ParityTaxExtt contract
        parityTaxExtt = new ParityTaxExtt();

        parityTaxHook = ParityTaxHook(
            address(
                uint160(
                    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG| 
                    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG | 
                    Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG | Hooks.BEFORE_SWAP_FLAG | 
                    Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_DONATE_FLAG
                )

            )
            
        );


        deployCodeTo(
            "ParityTaxHook.sol:ParityTaxHook",
            abi.encode(
                manager,
                lpm,
                lpOracle,
                parityTaxExtt
            ),
            address(parityTaxHook)
        );


        deployAndApproveResolvers(manager,lpm, parityTaxHook);

        fundResolvers();
        parityTaxHook.setLiquidityResolvers(plpResolver, jitResolver);
        

        deployAndApproveFiscalPolicy(callbackSender,manager,lpm,parityTaxHook);

        parityTaxHook.setFiscalPolicy(fiscalPolicy);

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
            

    function test__JIT__fulfills_ZeroForOneSwap() public {

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


    function test__PLP__accessControl() public{
        vm.roll(10_000);
        assertTrue(plpResolver.hasRole(bytes32(0x00), address(parityTaxHook)));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                bytes32(0x00)
            ),
            address(plpResolver)
        );
        vm.startPrank(alice);

        plpResolver.commitLiquidity(
            key,
            LIQUIDITY_PARAMS,
            alice,
            uint48(vm.getBlockNumber()) + uint48(0x02)
        );

        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                bytes32(0x00)
            ),
            address(plpResolver)
        );
        vm.startPrank(alice);

        plpResolver.removeLiquidity(
            key.toId(),
            uint256(0x01),
            REMOVE_LIQUIDITY_PARAMS.liquidityDelta
        );

        vm.stopPrank();
    }

    function test__PLP__commitLiquidity() public{

        console2.log("//========================BEFORE COMMIT LIQUIDITY STATE =========================");

        vm.roll(10_000);
        assertEq(10_000, vm.getBlockNumber());
        console2.log("Starting Block Number:", vm.getBlockNumber());
        console2.log("Liquidity Positions token Id counter:",lpm.nextTokenId());
        uint256 liquidityCommitmentTokenId = lpm.nextTokenId();
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency0)).balanceOf(alice));
        assertEq(STARTING_USER_BALANCE, IERC20(Currency.unwrap(key.currency1)).balanceOf(alice));
        console2.log("Let ALice be the PLP...");
        console2.log("PLP Has Starting Balance Of Both Currencies", STARTING_USER_BALANCE);

        console2.log("//============================COMMIT LIQUIDITY=====================================");
        console2.log("PLP cannot set a block number commitment that is less than or equal to one block");
        vm.expectRevert(
            // abi.encodeWithSelector(
            //     IParityTaxHook.InvalidPLPBlockCommitment.selector
            // )
        );
        vm.startPrank(alice);
            parityTaxRouter.modifyLiquidity(
                key,
                LIQUIDITY_PARAMS,
                JIT_COMMITMENT
            );
        vm.stopPrank();

        console2.log("PLP succesfully adds liquidity seting a block number commitment greater than or equal to one block");
        vm.startPrank(alice);
        BalanceDelta liquidityDelta = parityTaxRouter.modifyLiquidity(
            key,
            LIQUIDITY_PARAMS,
            MIN_PLP_BLOCK_NUMBER_COMMITMENT
        );
        vm.stopPrank();

        console2.log("//========================AFTER COMMIT LIQUIDITY STATE =========================");
        //TODO: Verify commitments per position
        console2.log("Alice is the owner of the last minted liquidity Position");
        vm.mockCall(
            address(lpm),
            abi.encodeWithSignature(
                "ownerOf(uint256)",
                liquidityCommitmentTokenId
            ),
            abi.encode(alice)
        );

        //NOTE: The liquidity on the Pool 
        console2.log("The Liquidity on the PLP Position Must equal the one specified on the router call");
        assertEq(
            uint128(int128(LIQUIDITY_PARAMS.liquidityDelta)),
            lpm.getPositionLiquidity(
                liquidityCommitmentTokenId
            )
        );
        console2.log("The Hook is kepping track of the commitments of the PLP");
        assertEq(
            parityTaxHook.getPositionBlockNumberCommitment(
                key.toId(),
                alice,
                liquidityCommitmentTokenId
            ),
            uint48(vm.getBlockNumber() + MIN_PLP_BLOCK_NUMBER_COMMITMENT)
        );
        console2.log("The Hook is keeping track of the fee revenue of the PLP");
        
        BalanceDelta plpFeeDelta = calculateFeeDelta(
            manager,
            key.toId(),
            address(lpm),
            lpm.positionInfo(liquidityCommitmentTokenId).tickLower(),
            lpm.positionInfo(liquidityCommitmentTokenId).tickUpper(),
            LIQUIDITY_PARAMS.salt
        );
        console2.log("There has not been any swaps, then the fees Accrued are zero");
        // assertEq(
        //     parityTaxHook.getWithheldFees(
        //         key.toId(),
        //         alice,
        //         liquidityCommitmentTokenId
        //     ),
        //     BalanceDeltaLibrary.ZERO_DELTA,
        //     ""
        // );
        
    
        //NOTE: This assertion is broken if terms of trade differ from one


        console2.log("The balance of the PLP has decreased by the amount of liquidity provided on both currencies");
        assertEq(IERC20(Currency.unwrap(key.currency0)).balanceOf(alice), uint256(int256(STARTING_USER_BALANCE) + int256(liquidityDelta.amount0())));
        assertEq(IERC20(Currency.unwrap(key.currency1)).balanceOf(alice), uint256(int256(STARTING_USER_BALANCE) + int256(liquidityDelta.amount1())));
        
        
        // Verify Pool Liquidity
        // Verify PLP balance and PLP owned liquidity on pool

    }

    function test__PLP__removeLiquidity() public{
        console2.log("//========================BEFORE REMOVE LIQUIDITY STATE =========================");

        vm.roll(10_000);
        assertEq(10_000, vm.getBlockNumber());
        console2.log("Starting Block Number:", vm.getBlockNumber());
        console2.log("Liquidity Positions token Id counter:",lpm.nextTokenId());
        uint256 liquidityCommitmentTokenId = lpm.nextTokenId();

        console2.log("PLP cannot withdraw from the position within the same block (i.e., it cannot instantly act as JIT).");
        //NOTE: Let's have the PLP try to remove liquidity from the same router
        
        vm.startPrank(alice);
        BalanceDelta liquidityDelta = parityTaxRouter.modifyLiquidity(
            key,
            LIQUIDITY_PARAMS,
            MIN_PLP_BLOCK_NUMBER_COMMITMENT
        );
        vm.mockCallRevert(
            address(parityTaxRouter),
            abi.encodeCall(
                IParityTaxRouter.modifyLiquidity,
                (key,REMOVE_LIQUIDITY_PARAMS,JIT_COMMITMENT)
            ),
            abi.encodePacked(IParityTaxHook.NotWithdrawableLiquidity__LiquidityIsCommitted.selector)
        );
        
        vm.stopPrank();



        console2.log("PLP Can not remove committed liquidity from an external router");
        PositionInfo plpPositionInfo = lpm.positionInfo(liquidityCommitmentTokenId);

        // Try to remove liquidity in the same block - should fail
        
        
        vm.startPrank(alice);
        bytes memory config = getDecreaseEncoded(
            liquidityCommitmentTokenId,
            PositionConfig({
                poolKey: key,
                tickLower: plpPositionInfo.tickLower(),
                tickUpper: plpPositionInfo.tickUpper()
            }),

            uint256(lpm.getPositionLiquidity(liquidityCommitmentTokenId)),
            bytes("")
        );
        vm.mockCallRevert(
            address(lpm),
            abi.encodeCall(
                IPositionManager.modifyLiquidities,
                (config,_deadline)
            ),

            abi.encodeWithSelector(
                IParityTaxHook.InvalidPLPBlockCommitment.selector
            )
        );

        vm.stopPrank();


        //NOTE: Let's have the PLP try to remove liquidity from another router from where
        // it initally added the position

    }


    



}

