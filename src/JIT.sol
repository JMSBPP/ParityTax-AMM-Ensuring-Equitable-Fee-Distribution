// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IStateView} from "@uniswap/v4-periphery/src/interfaces/IStateView.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// This contract aims to be a calculator of JIT operations
import {Pool} from "@uniswap/v4-core/src/libraries/Pool.sol";
import {PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Slot0, Slot0Library} from "@uniswap/v4-core/src/types/Slot0.sol";

abstract contract JIT is Initializable {
    using PoolIdLibrary for PoolKey;
    using Slot0Library for Slot0;
    /// @custom:storage-location erc7201:openzeppelin.storage.JIT    
    struct JITStorage{
        IPoolManager _poolManager;
        IStateView _stateView;
        PoolKey _poolKey;
    }
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.JIT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant JITStorageLocation = 0x2a45e999019fda730a9321cc467338cd05c558f189040d015df82e533397c600;

    function _getJITStorage() private pure returns (JITStorage storage $) {
        assembly {
            $.slot := JITStorageLocation
        }
    }

    function poolKey() public view returns(PoolKey memory __poolKey){
        JITStorage storage $ = _getJITStorage();
        __poolKey = $._poolKey;
    }

    function poolManager() public view returns(IPoolManager manager){
        JITStorage storage $ = _getJITStorage();
        manager = $._poolManager;
    }

    function stateView() public view returns(IStateView viewer){
        JITStorage storage $ = _getJITStorage();
        viewer = $._stateView;
    }

    function initialize(
        PoolKey calldata key,
        IPoolManager  manager,
        IStateView viewer
    ) public virtual initializer {
        JITStorage storage $ = _getJITStorage();
        $._poolManager = manager;
        $._poolKey = key;
        $._stateView = viewer;
    }

    function _buildPoolState() private{
        PoolId poolId = poolKey().toId();
        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = stateView().getSlot0(poolId);
        Slot0 _slot0 = Slot0.wrap(bytes32(uint256(0x00))).setSqrtPriceX96(sqrtPriceX96).setTick(tick).setProtocolFee(protocolFee).setLpFee(lpFee);
        (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) = stateView().getFeeGrowthGlobals(poolId);
    } 

    /// @notice Defines the amount of tokens to be used in the JIT position
    /// @dev No tokens should be transferred into the PoolManager by this function. The afterSwap implementation, will handle token flows
    /// @param params the swap params passed in during swap
    /// @param data external call data to quote for custom curves
    /// @return amount0 the amount of currency0 to be used for JIT position
    /// @return amount1 the amount of currency1 to be used for JIT position
    function _jitAmounts(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes memory data
    ) internal virtual returns (uint128, uint128)
        {
            
            uint256 amountOut;
            uint256 amountIn;
            bool isExactInput = params.amountSpecified < 0;
            if (isExactInput) {
                amountIn = uint256(-params.amountSpecified);
                // NOTE: Here it allows for custom quoting by the bytes memory data param
                if (data.length > 0){
                    // NOTE: It allows the excecution of custom logic
                    
                }else {

                }

                // amountOut = QuoteLib.computeQuote(evc, p, params.zeroForOne, amountIn, true);
            } else {
                amountOut = uint256(params.amountSpecified);
                // amountIn = QuoteLib.computeQuote(evc, p, params.zeroForOne, amountOut, false);
            }

            // return the delta to the PoolManager, so it can process the accounting
            // exact input:
            //   specifiedDelta = positive, to offset the input token taken by the hook (negative delta)
            //   unspecifiedDelta = negative, to offset the credit of the output token paid by the hook (positive delta)
            // exact output:
            //   specifiedDelta = negative, to offset the output token paid by the hook (positive delta)
            //   unspecifiedDelta = positive, to offset the input token taken by the hook (negative delta)
            // returnDelta = isExactInput
            //    ? toBeforeSwapDelta(amountIn.toInt128(), -(amountOut.toInt128()))
            //    : toBeforeSwapDelta(-(amountOut.toInt128()), amountIn.toInt128());

            // take the input token, from the PoolManager to the Euler vault
            // the debt will be paid by the swapper via the swap router
            poolManager().take(params.zeroForOne ? key.currency0 : key.currency1, address(this), amountIn);
            // amountInWithoutFee = FundsLib.depositAssets(evc, p, params.zeroForOne ? p.vault0 : p.vault1);

            // pay the output token, to the PoolManager from an Euler vault
            // the credit will be forwarded to the swap router, which then forwards it to the swapper
            poolManager().sync(params.zeroForOne ? key.currency1 : key.currency0);
            // FundsLib.withdrawAssets(evc, p, params.zeroForOne ? p.vault1 : p.vault0, amountOut, address(poolManager));
            poolManager().settle();
        
        }


}
