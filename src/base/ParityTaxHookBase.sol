//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import {
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
//==================================================================
import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
//====================================================================

//==============================================================
import "../types/Shared.sol";
import {IPLPResolver} from "../interfaces/IPLPResolver.sol";
import {IJITResolver} from "../interfaces/IJITResolver.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";
import {IFiscalPolicy} from "../interfaces/IFiscalPolicy.sol";
import {ILPOracle} from "../interfaces/ILPOracle.sol";
import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
//==============================================================


import {Exttload} from "@uniswap/v4-core/src/Exttload.sol";
import {LiquidityMetrics} from "../LiquidityMetrics.sol";


abstract contract ParityTaxHookBase is IParityTaxHook,Exttload,BaseHook, LiquidityMetrics{


    using SafeCast for *;
    using Position for address;
    using PositionInfoLibrary for PoolKey;
    using CurrencySettler for Currency;
    using PositionInfoLibrary for PositionInfo;
    using StateLibrary for IPoolManager;

    IPLPResolver plpResolver;
    IJITResolver jitResolver;
    IPositionManager lpm;
    IFiscalPolicy fiscalPolicy;
    ILPOracle lpOracle;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant public JIT_LIQUIDITY_POSITION_LOCATION = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.PLP_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant public PLP_LIQUIDITY_POSITION_LOCATION = 0x369fcc6be4409721b124e1944af5cd9c5a8ac6c841854a0f264aead4f039bb00;
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.PRICE_IMPACT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant public PRICE_IMPACT_LOCATION = 0x9a6e024ebb4e856a20885b7e11ce369a95696ac0f9ef8bcb2bc66a08583efa00;


    // TODO: This are to be migrated to enumerable mappings fo iteration ...
    mapping(PoolId poolId => mapping(address owner => mapping(uint256 tokenId => uint48 blockNumberCommitment))) internal _plpBlockNumberCommitmnet;
    // mapping(PoolId poolId => mapping(address owner => mapping(uint256 tokenId => BalanceDelta delta))) internal _withheldFees;


    modifier onlyPositionManager(address _router){
        if (_router != address(lpm)) revert InvalidLiquidityRouterCaller();
        _;
    }

    modifier onlyPositionManagerForJIT(address _router){
        if ( _router != address(lpm) && _tload_jit_tokenId() > uint256(0x00) ) revert InvalidLiquidityRouterCaller();
        _;
    }
    


    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        ILPOracle _lpOracle
    ) BaseHook(_poolManager) LiquidityMetrics(_poolManager){
        lpm = _lpm;
        lpOracle = _lpOracle;
    }

    function setLiquidityResolvers(
        IPLPResolver _plpResolver,
        IJITResolver _jitResolver
    ) external {
        plpResolver = _plpResolver;
        jitResolver = _jitResolver;
    }

    function setFiscalPolicy(
        IFiscalPolicy _fiscalPolicy
    ) external {
        fiscalPolicy = _fiscalPolicy;
    }


    function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory){
        return Hooks.Permissions({
            beforeInitialize: true,      // NOTE: ILPOracle -> sync the internal price with the external one
            afterInitialize: false,  
            beforeAddLiquidity: true,    //NOTE: Handles the commitment of PLP's and JIT's 
            afterAddLiquidity: true,     //NOTE:
            beforeRemoveLiquidity: true, //NOTE:
            afterRemoveLiquidity: true,  //NOTE:
            beforeSwap: true,            //NOTE:
            afterSwap: true,             //NOTE:
            beforeDonate: false,
            afterDonate: true,       //NOTE: It allows for custom tax income distribution mechanisms among PLP;s
            beforeSwapReturnDelta:false,  
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: true, //NOTE:
            afterRemoveLiquidityReturnDelta: true //NOTE:
        });
    }

    function getLiquidityPosition(
        PoolKey memory poolKey,
        LP_TYPE lpType,
        address owner,
        uint256 tokenId
    ) public view returns (LiquidityPosition memory liquidityPositionData){
        PoolId poolId = poolKey.toId();

        uint256 liquidity = lpm.getPositionLiquidity(tokenId);
        
        PositionInfo positionInfo = lpm.positionInfo(tokenId);
        
        bytes32 lpTypePositionKey = address(lpm).calculatePositionKey(
            positionInfo.tickLower(),
            positionInfo.tickUpper(),
            bytes32(tokenId)
        );

        (,uint256 feeRevenueOn0, uint256 feeRevenueOn1) = poolManager.getPositionInfo(
            poolId,
            lpTypePositionKey
        );

        liquidityPositionData = LiquidityPosition({
                lpType: lpType,
                blockCommitment: lpType == LP_TYPE.PLP ? getPositionBlockNumberCommitment(poolId,owner,tokenId): JIT_COMMITMENT,
                owner: owner,
                tokenId: tokenId,
                positionKey: lpTypePositionKey,
                positionInfo: positionInfo,
                liquidity: liquidity,
                feeRevenueOnCurrency0: feeRevenueOn0,
                feeRevenueOnCurrency1: feeRevenueOn1
        });
    }

    //TODO: This functions are tobe protected to onyl be called by the parityTaxRouter or
    // the taxController 
    function tstore_plp_liquidity(int256 liquidityChange) external{
        _tstore_plp_liquidity(liquidityChange);
    }

    function tstore_plp_feesAccrued(uint256 feesAccruedOn0, uint256 feesAccruedOn1) external{
        _tstore_plp_feesAccrued(feesAccruedOn0,feesAccruedOn1);
    }



    function _tstore_plp_liquidity(int256 liquidityChange) internal virtual{
        assembly("memory-safe"){
            tstore(PLP_LIQUIDITY_POSITION_LOCATION, liquidityChange)
        }
    }

    function _tstore_plp_feesAccrued(uint256 feesAccruedOn0, uint256 feesAccruedOn1) internal virtual{
        assembly("memory-safe"){
            tstore(add(PLP_LIQUIDITY_POSITION_LOCATION,0x01), feesAccruedOn0)
            tstore(add(PLP_LIQUIDITY_POSITION_LOCATION,0x02), feesAccruedOn1)

        }
    }

    function _tstore_plp_tokenId(uint256 tokenId) internal{
        assembly("memory-safe"){
            tstore(add(PLP_LIQUIDITY_POSITION_LOCATION,0x03), tokenId)
        }
    }



    function _tstore_swap_beforeSwapSqrtPriceX96(uint160 beforeSwapSqrtPriceX96 ) internal{
        assembly("memory-safe"){
            tstore(PRICE_IMPACT_LOCATION, beforeSwapSqrtPriceX96)
        }
    }

    function _tstore_swap_beforeSwapExternalSqrtPriceX96(uint160 beforeSwapExternalSqrtPriceX96 ) internal{
        assembly("memory-safe"){
            tstore(add(PRICE_IMPACT_LOCATION,0x01), beforeSwapExternalSqrtPriceX96)
        }
    }




    function _tstore_jit_tokenId(uint256 tokenId) internal{
        assembly("memory-safe"){
            tstore(JIT_LIQUIDITY_POSITION_LOCATION, tokenId)
        }
    }

    function _tstore_jit_feeRevenue(
        uint256 feeRevenueOn0,
        uint256 feeRevenueOn1
    ) internal {
        assembly("memory-safe"){
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x04), feeRevenueOn0)
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x05), feeRevenueOn1)
        }
    }

    function _tstore_jit_positionInfo(
        PositionInfo positionInfo
    ) internal{
        bytes32 lpPositionInfo = bytes32(PositionInfo.unwrap(
            positionInfo
        ));
        assembly("memory-safe"){
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x02), lpPositionInfo)
        }
    }

    function _tstore_jit_liquidity(
        uint256 liquidity
    ) internal{
        assembly("memory-safe"){
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x03), liquidity)
        }
    }

    function _tstore_jit_positionKey(
        bytes32 positionKey
    ) internal{
        assembly("memory-safe"){
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x01), positionKey)
        }
    }

    function _tstore_jit_owner(
        address owner
    ) internal{
        assembly("memory-safe"){
            tstore(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x06), owner)
        }
    }

    
    function _tstore_jit_liquidityPosition(LiquidityPosition memory jitLiquidityPosition) internal{
        
        _tstore_jit_positionKey(jitLiquidityPosition.positionKey);
        _tstore_jit_liquidity(
            jitLiquidityPosition.liquidity
        );
        _tstore_jit_positionInfo(jitLiquidityPosition.positionInfo);
        _tstore_jit_feeRevenue(
            jitLiquidityPosition.feeRevenueOnCurrency0,
            jitLiquidityPosition.feeRevenueOnCurrency1
        );
        _tstore_jit_owner(jitLiquidityPosition.owner);
    }

    function _tload_plp_tokenId() internal view returns(uint256 tokenId){
        assembly("memory-safe"){
            tokenId := tload(add(PLP_LIQUIDITY_POSITION_LOCATION, 0x03))
        }

    }

    function _tload_swap_beforeSwapSqrtPriceX96() internal returns(uint160){
        uint256 _beforeSwapSqrtPriceX96;
        assembly("memory-safe"){
            _beforeSwapSqrtPriceX96 := tload(PRICE_IMPACT_LOCATION)
        }
        return uint160(_beforeSwapSqrtPriceX96);
    }

    function _tload_swap_beforeSwapExternalSqrtPriceX96() internal returns(uint160){
        uint256 _beforeSwapExternalSqrtPriceX96;
        assembly("memory-safe"){
            _beforeSwapExternalSqrtPriceX96 := tload(add(PRICE_IMPACT_LOCATION,0x01))
        }
        return uint160(_beforeSwapExternalSqrtPriceX96);
    }

    // NOTE: This function is to be called during JIT Resolver removeLiqudity Flow
    function _tload_jit_tokenId() internal view returns(uint256 jitTokenId){
        assembly("memory-safe"){
            jitTokenId := tload(JIT_LIQUIDITY_POSITION_LOCATION)
        }
    }

    function _tload_jit_positionInfo() internal view returns(PositionInfo jitPositionInfo){
        bytes32 positionInfo;
        assembly("memory-safe"){
            positionInfo := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x02))
        
        }
        jitPositionInfo = PositionInfo.wrap(uint256(positionInfo));
    }

    function _tload_jit_positionKey() internal view returns(bytes32 jitPositionKey){
        assembly("memory-safe"){
            jitPositionKey := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x01))
        }
    }

    function _tload_jit_liquidity() internal view returns(uint256 jitLiquidity){
        assembly("memory-safe"){
            jitLiquidity := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x03))
        }
    }

    function _tload_jit_feeRevenue() internal view returns(uint256,uint256){
        uint256 feesOn0;
        uint256 feesOn1;

        assembly("memory-safe"){
            feesOn0 := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x04))
            feesOn1 := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x05))
        }

        return (feesOn0, feesOn1);
    }

    function _tload_jit_owner() internal view returns(address owner){
        assembly("memory-safe"){
            owner := tload(add(JIT_LIQUIDITY_POSITION_LOCATION, 0x06))
        }
    }



    function _tload_jit_liquidityPosition() internal returns(LiquidityPosition memory jitLiquidityPosition){
        (uint256 feesOn0,uint256 feesOn1) = _tload_jit_feeRevenue();

        jitLiquidityPosition = LiquidityPosition({
            lpType: LP_TYPE.JIT,
            blockCommitment: JIT_COMMITMENT,
            owner: _tload_jit_owner(),
            tokenId: _tload_jit_tokenId(),
            positionKey: _tload_jit_positionKey(),
            positionInfo: _tload_jit_positionInfo(),
            liquidity: _tload_jit_liquidity(),
            feeRevenueOnCurrency0: feesOn0,
            feeRevenueOnCurrency1: feesOn1       
        });
    }


    function _getPoolIdAndPositionKey(
        address liquidityRouter,
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams
    ) internal view returns(PoolId poolId, bytes32 lpPositionKey){
        poolId = poolKey.toId();
        
        lpPositionKey = liquidityRouter.calculatePositionKey(
            liquidityParams.tickLower,
            liquidityParams.tickUpper,
            liquidityParams.salt
        );
    }

    function _lockLiquidity(
        PoolId poolId,
        uint256 tokenId,
        address owner,
        uint48 blockNumberCommitment
    ) internal virtual {
        _plpBlockNumberCommitmnet[poolId][owner][tokenId] =blockNumberCommitment; 
    }

    // function _withholdFeeRevenue(
    //     PoolKey memory poolKey,
    //     address owner,
    //     uint256 lpPositionTokenId,
    //     BalanceDelta feeRevenueDelta
    // ) internal virtual {
    //     PoolId poolId = poolKey.toId();
    //      _withheldFees[poolId][owner][lpPositionTokenId] = _withheldFees[poolId][owner][lpPositionTokenId] + feeRevenueDelta;

    //     poolKey.currency0.take(poolManager, address(this), uint256(uint128(feeRevenueDelta.amount0())), true);
    //     poolKey.currency1.take(poolManager, address(this), uint256(uint128(feeRevenueDelta.amount1())), true);
    // }




    function _clearPositionBlockNumberCommitment(
        PoolId poolId,
        address owner,
        uint256 tokenId
    ) internal virtual {
        _plpBlockNumberCommitmnet[poolId][owner][tokenId] = NO_COMMITMENT;
    }

    // function _remitFeeRevenue(
    //     PoolKey memory poolKey,
    //     address owner,
    //     uint256 tokenId
    // ) internal virtual returns(BalanceDelta withheldFees) {
        
    //     PoolId poolId = poolKey.toId();
        
    //     withheldFees = _withheldFees[poolId][owner][tokenId];
        
    //     _withheldFees[poolId][owner][tokenId] = BalanceDeltaLibrary.ZERO_DELTA;

    //     if (withheldFees.amount0() > 0) {
    //         poolKey.currency0.settle(poolManager, address(this), uint256(uint128(withheldFees.amount0())), true);
    //     }
    //     if (withheldFees.amount1() > 0) {
    //         poolKey.currency1.settle(poolManager, address(this), uint256(uint128(withheldFees.amount1())), true);
    //     }

    // }


    // function getSqrtPriceImpactX96() public view returns(uint160[] memory){
    //     return metrics.sqrtPriceImpactX96;
    // }

    function getPositionBlockNumberCommitment(
        PoolId poolId,
        address owner,
        uint256 tokenId
    ) public virtual view returns(uint48){
        return _plpBlockNumberCommitmnet[poolId][owner][tokenId];
    }







    //TODO: This is a place holder, to be implemented
    function getCurrentPrice() public view returns(uint256){
        return 1;
    }

    

    function positionManager() external returns(IPositionManager){
        return lpm;
    }

    function FiscalPolicy() external returns(IFiscalPolicy){
        return fiscalPolicy;
    }

}