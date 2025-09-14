//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "../types/SwapIntent.sol";
import "./ISwapMetrics.sol";
import "./ILiquidityMetrics.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {ITaxController} from "./ITaxController.sol";
import {IExttload} from "@uniswap/v4-core/src/interfaces/IExttload.sol";
import {IPLPResolver} from "./IPLPResolver.sol";
import {IJITResolver} from "./IJITResolver.sol";


interface IParityTaxHook is IExttload{


    event PriceImpact(
        bytes32 indexed poolId,
        uint48 indexed blockNumber,
        SwapIntent indexed swapIntent,
        BalanceDelta swapDelta,
        uint160 beforeSwapSqrtPriceX96,
        uint160 beforeSwapExternalSqrtPriceX96,
        uint160 afterSwapSqrtPriceX96,
        uint160 afterSwapExternalSqrtPriceX96
    );


    event LiquidityOnSwap(bytes32 indexed poolId, uint48 indexed blockNumber, uint128 totalLiquidity, uint128 jitLiquidity, uint128 plpLiquidity);
    
    event LiquidityCommitted(
        bytes32 indexed poolId,
        uint48 indexed blockNumber,
        uint48 indexed commitment,
        address indexed owner,
        uint256 tokenId,
        bytes liquidityParams
    ) anonymous;
    
    
    error AmountOutGreaterThanSwapAmountOut();
    error NotEnoughLiquidity(PoolId poolId);
    error NotWithdrawableLiquidity__LiquidityIsCommitted();
    error NoLiquidityToReceiveTaxRevenue();
    error CurrencyMissmatch();
    error NoLiquidityToReceiveTaxCredit();
    error InvalidLiquidityRouterCaller();
    error InvalidPLPBlockCommitment();

    //TODO: I need to expose the queries available to the router


    //NOTE:The router can (with access control) store on Hook's transient storage

    function tstore_plp_liquidity(int256 liquidityChange) external;

    function tstore_plp_feesAccrued(uint256 feesAccruedOn0, uint256 feesAccruedOn1) external;

    function positionManager() external returns(IPositionManager);
 
    function TaxController() external returns(ITaxController);

    function setLiquidityResolvers(
        IPLPResolver _plpResolver,
        IJITResolver _jitResolver
    ) external;


    function getPositionBlockNumberCommitment(
        PoolId poolId,
        address owner,
        uint256 tokenId
    ) external view returns(uint48);

    function getWithheldFees(
        PoolId poolId, 
        address owner,
        uint256 tokenId
    ) external view returns (BalanceDelta);



}