// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Quoter,V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "@uniswap/v4-core/src/libraries/TransientStateLibrary.sol";

import {
    SwapParams,
    ModifyLiquidityParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";


import "./types/Shared.sol";

import {SafeCallback} from "@uniswap/v4-periphery/src/base/SafeCallback.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {IParityTaxRouter} from "./interfaces/IParityTaxRouter.sol";

import {console2} from "forge-std/Test.sol";

contract ParityTaxRouter is IParityTaxRouter, SafeCallback{
    using SafeCast for *;
    using SqrtPriceMath for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    


    IV4Quoter v4Quoter;

    error InvalidPLPLiquidityCommitment();

    constructor(
        IPoolManager _poolManager,
        IV4Quoter _v4Quoter
    ) SafeCallback(_poolManager){
        v4Quoter = _v4Quoter;
    }

    function modifyLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        uint48 plpLiquidityBlockCommitment 
    ) external payable returns (BalanceDelta delta){
        if (plpLiquidityBlockCommitment < MIN_PLP_BLOCK_NUMBER_COMMITMENT) revert InvalidPLPLiquidityCommitment();
        bytes memory hookData = abi.encode(plpLiquidityBlockCommitment);
        bytes memory encodedLiquidityCallbackData = abi.encode(
                    ModifyLiquidityCallBackData(
                        msg.sender,
                        poolKey,
                        liquidityParams,
                        hookData
                    )
                );
        delta = abi.decode(
            poolManager.unlock(
                abi.encode(
                   encodedLiquidityCallbackData
                )
            ),
            (BalanceDelta)
        );

    }

    function swap(
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external payable returns (BalanceDelta delta)
    {
        (uint160 beforeSwapSqrtPriceX96,int24 beforeSwapTick,,uint24 lpFee) = poolManager.getSlot0(poolKey.toId());
 
        int24 expectedAfterSwapTick;
        uint160 expectedSqrtPriceImpactX96;
        uint128 jitLiquidity;

        uint128 plpLiquidity;
        uint256 amountIn;
        uint256 amountOut;
        bool isExactInput = swapParams.amountSpecified <0;
        bool zeroForOne = swapParams.zeroForOne;

        {
            PoolKey memory noHookKey = PoolKey({
                                            currency0: poolKey.currency0,
                                            currency1: poolKey.currency1,
                                            fee: poolKey.fee,
                                            tickSpacing: poolKey.tickSpacing,
                                            hooks: IHooks(address(0x00))
                                        });
            if (isExactInput){
                amountIn = uint256(-swapParams.amountSpecified);
                (amountOut,) = v4Quoter.quoteExactInputSingle(
                    IV4Quoter.QuoteExactSingleParams({
                        poolKey: noHookKey,
                        zeroForOne: swapParams.zeroForOne,
                        exactAmount: (-swapParams.amountSpecified).toInt128().toUint128(),
                        hookData: Constants.ZERO_BYTES
                    })
                );
            } else {
                amountOut = uint256(swapParams.amountSpecified);
                (amountIn,) = v4Quoter.quoteExactOutputSingle(
                    IV4Quoter.QuoteExactSingleParams({
                        poolKey: noHookKey,
                        zeroForOne: swapParams.zeroForOne,
                        exactAmount: swapParams.amountSpecified.toInt128().toUint128(),
                        hookData: Constants.ZERO_BYTES
                    })
                );

            }

        }

        {
            plpLiquidity = poolManager.getLiquidity(poolKey.toId());
            
            uint160 expectedAfterSwapSqrtPriceX96 = isExactInput ? beforeSwapSqrtPriceX96.getNextSqrtPriceFromOutput(
                plpLiquidity,
                amountOut,
                zeroForOne
            ) : beforeSwapSqrtPriceX96.getNextSqrtPriceFromInput(
                plpLiquidity,
                amountIn,
                zeroForOne
            );
  
            // NOTE: The tick of such after price nees to be rounded to the nearest tick
            // based on the tickSpacing of the pool
            expectedAfterSwapTick = (expectedAfterSwapSqrtPriceX96.getTickAtSqrtPrice().compress(poolKey.tickSpacing))*int24(poolKey.tickSpacing);

        }

        bytes memory hookData = abi.encode(
            JITData({
                poolKey: poolKey,
                amountSpecified: swapParams.amountSpecified,
                amountIn: amountIn,
                amountOut: amountOut,
                token0: Currency.unwrap(poolKey.currency0),
                sqrtPriceLimitX96: swapParams.sqrtPriceLimitX96,
                token1: Currency.unwrap(poolKey.currency1),
                beforeSwapSqrtPriceX96:beforeSwapSqrtPriceX96,
                plpLiquidity:plpLiquidity,
                expectedAfterSwapSqrtPriceX96:expectedAfterSwapTick.getSqrtPriceAtTick(),
                expectedAfterSwapTick:expectedAfterSwapTick,
                zeroForOne: swapParams.zeroForOne
            })
        );
        bytes memory encodedSwapCallBackData = abi.encode(
                    SwapCallbackData(
                        msg.sender,
                        poolKey,
                        swapParams,
                        hookData)
                    );
        console2.log("Swap CallBackData lenght:", encodedSwapCallBackData.length);
        delta = abi.decode(
            poolManager.unlock(
                encodedSwapCallBackData
                ),
            (BalanceDelta)
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) CurrencyLibrary.ADDRESS_ZERO.transfer(msg.sender, ethBalance);
    }


    function _unlockCallback(bytes calldata rawData) internal override returns (bytes memory) {
        require(msg.sender == address(poolManager));
        BalanceDelta delta;

        if (rawData.length == SWAP_CALLBACK_DATA_LENGTH){
            SwapCallbackData memory data = abi.decode(rawData, (SwapCallbackData));

            (,, int256 deltaBefore0) = _fetchBalances(data.key.currency0, data.sender, address(this));
            (,, int256 deltaBefore1) = _fetchBalances(data.key.currency1, data.sender, address(this));

            require(deltaBefore0 == 0, "deltaBefore0 is not equal to 0");
            require(deltaBefore1 == 0, "deltaBefore1 is not equal to 0");

            delta = poolManager.swap(data.key, data.params, data.hookData);

            (,, int256 deltaAfter0) = _fetchBalances(data.key.currency0, data.sender, address(this));
            (,, int256 deltaAfter1) = _fetchBalances(data.key.currency1, data.sender, address(this));

            if (data.params.zeroForOne) {
                if (data.params.amountSpecified < 0) {
                    // exact input, 0 for 1
                    require(
                        deltaAfter0 >= data.params.amountSpecified,
                        "deltaAfter0 is not greater than or equal to data.params.amountSpecified"
                    );
                    require(delta.amount0() == deltaAfter0, "delta.amount0() is not equal to deltaAfter0");
                    require(deltaAfter1 >= 0, "deltaAfter1 is not greater than or equal to 0");
                } else {
                    // exact output, 0 for 1
                    require(deltaAfter0 <= 0, "deltaAfter0 is not less than or equal to zero");
                    require(delta.amount1() == deltaAfter1, "delta.amount1() is not equal to deltaAfter1");
                    require(
                        deltaAfter1 <= data.params.amountSpecified,
                        "deltaAfter1 is not less than or equal to data.params.amountSpecified"
                    );
                }
            } else {
                if (data.params.amountSpecified < 0) {
                    // exact input, 1 for 0
                    require(
                        deltaAfter1 >= data.params.amountSpecified,
                        "deltaAfter1 is not greater than or equal to data.params.amountSpecified"
                    );
                    require(delta.amount1() == deltaAfter1, "delta.amount1() is not equal to deltaAfter1");
                    require(deltaAfter0 >= 0, "deltaAfter0 is not greater than or equal to 0");
                } else {
                    // exact output, 1 for 0
                    require(deltaAfter1 <= 0, "deltaAfter1 is not less than or equal to 0");
                    require(delta.amount0() == deltaAfter0, "delta.amount0() is not equal to deltaAfter0");
                    require(
                        deltaAfter0 <= data.params.amountSpecified,
                        "deltaAfter0 is not less than or equal to data.params.amountSpecified"
                    );
                }
            }

            if (deltaAfter0 < 0) {
                data.key.currency0.settle(poolManager, data.sender, uint256(-deltaAfter0), false);
            }
            if (deltaAfter1 < 0) {
                data.key.currency1.settle(poolManager, data.sender, uint256(-deltaAfter1), false);
            }
            if (deltaAfter0 > 0) {
                data.key.currency0.take(poolManager, data.sender, uint256(deltaAfter0), false);
            }
            if (deltaAfter1 > 0) {
                data.key.currency1.take(poolManager, data.sender, uint256(deltaAfter1), false);
            }

            return abi.encode(delta);
        // TODO: bytes length cheching for routing on liquidity modifications
        } else {

            ModifyLiquidityCallBackData memory data = abi.decode(rawData, (ModifyLiquidityCallBackData));
            (uint128 liquidityBefore,,) = poolManager.getPositionInfo(
                data.key.toId(), address(this), data.params.tickLower, data.params.tickUpper, data.params.salt
            );

            (delta,) = poolManager.modifyLiquidity(data.key, data.params, data.hookData);

            (uint128 liquidityAfter,,) = poolManager.getPositionInfo(
                data.key.toId(), address(this), data.params.tickLower, data.params.tickUpper, data.params.salt
            );

            (,, int256 delta0) = _fetchBalances(data.key.currency0, data.sender, address(this));
            (,, int256 delta1) = _fetchBalances(data.key.currency1, data.sender, address(this));

            require(
                int128(liquidityBefore) + data.params.liquidityDelta == int128(liquidityAfter), "liquidity change incorrect"
            );

            if (data.params.liquidityDelta < 0) {
                assert(delta0 > 0 || delta1 > 0);
                assert(!(delta0 < 0 || delta1 < 0));
            } else if (data.params.liquidityDelta > 0) {
                assert(delta0 < 0 || delta1 < 0);
                assert(!(delta0 > 0 || delta1 > 0));
            }

            if (delta0 < 0) data.key.currency0.settle(poolManager, data.sender, uint256(-delta0),false);
            if (delta1 < 0) data.key.currency1.settle(poolManager, data.sender, uint256(-delta1), false);
            if (delta0 > 0) data.key.currency0.take(poolManager, data.sender, uint256(delta0), false);
            if (delta1 > 0) data.key.currency1.take(poolManager, data.sender, uint256(delta1), false);

            return abi.encode(delta);
        } 

        
    }


    
    
    
    
    
    
    
    
    
    
    
    /// @dev Taken from @PoolTestBase
    function _fetchBalances(Currency currency, address user, address deltaHolder)
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = currency.balanceOf(user);
        poolBalance = currency.balanceOf(address(poolManager));
        delta = poolManager.currencyDelta(deltaHolder, currency);
    }


}

