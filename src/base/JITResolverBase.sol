//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IJITResolver.sol";
import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import "./ResolverBase.sol";

import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {SwapIntent,SwapIntentLibrary} from "../types/SwapIntent.sol";
import {PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

abstract contract JITResolverBase is IJITResolver, ResolverBase{
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) ResolverBase(_poolManager, _lpm, _parityTaxHook){}

    // NOTE: The add liquidity method is only called by the hook


    function addLiquidity(SwapContext memory swapContext) external onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256,uint256){
        //NOTE: The Hook needs to be the msg.sender
        //TODO: Further security checks using introspection for this ERC165
        
        _addLiquidity(swapContext);
    }

    function removeLiquidity(LiquidityPosition memory liquidityPosition) onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE) external{
        _removeLiquidity(liquidityPosition.tokenId);
    }


    function _addLiquidity(SwapContext memory) internal virtual returns(uint256,uint256);

    function _removeLiquidity(uint256) internal virtual;



}







