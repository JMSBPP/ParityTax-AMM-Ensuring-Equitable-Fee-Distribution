// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IFiscalPolicy.sol";
import {FeeRevenueInfoLibrary} from "../types/FeeRevenueInfo.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {PoolKey,PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {ILPOracle} from "../interfaces/ILPOracle.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";
import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";

import "../types/Shared.sol"; 

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

//===================================PROXY=======================================
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

//============================REACTIVE NETWORK =================================

import {AbstractCallback} from "@reactive-network/abstract-base/AbstractCallback.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";

import {console2} from "forge-std/Test.sol";



import {Planner, Plan} from "@uniswap/v4-periphery/test/shared/Planner.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";


abstract contract FiscalPolicyBase is IFiscalPolicy, UUPSUpgradeable, AbstractCallback{
    using PoolIdLibrary for PoolKey;
    using FeeRevenueInfoLibrary for FeeRevenueInfo;
    using PositionInfoLibrary for PositionInfo;
    using Address for address;
    using SafeCast for *;
    using BalanceDeltaLibrary for BalanceDelta;

    bytes32 constant internal TAX_RATE_SLOT = 0x27ab0422f76b78bf083331c8c5fff9ffc12f6849edb4cd1117fbfe5487d3ed00;

    ILPOracle _lpOracle;
    IPositionManager lpm;
    IParityTaxHook parityTaxHook;

    constructor(
        address _callbackSender,
        ILPOracle __lpOracle,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) AbstractCallback(_callbackSender){
        _lpOracle = __lpOracle;
        lpm = _lpm;
        parityTaxHook = _parityTaxHook;
    }



    function remit(PoolId poolId,FeeRevenueInfo feeRevenueInfo) external returns(BalanceDelta){
        
        _remit(poolId, feeRevenueInfo); 
        if (feeRevenueInfo.commitment() == JIT_COMMITMENT){
            _applyTax(poolId,feeRevenueInfo);

        }

    }


    function _applyTax(PoolId poolId, FeeRevenueInfo feeRevenueInfo) internal virtual{
        BalanceDelta jitFeeRevenueDelta = feeRevenueInfo.toBalanceDelta();
        console2.log("Balance Delta:", BalanceDelta.unwrap(jitFeeRevenueDelta));
        BalanceDelta jitTaxPaymentDelta = _calculateTaxPayment(jitFeeRevenueDelta);
        console2.log("Tax Payment Delta:", BalanceDelta.unwrap(jitTaxPaymentDelta));
        console2.log("JIT Liquidity Liability:", BalanceDelta.unwrap(jitFeeRevenueDelta - jitTaxPaymentDelta));
        PositionInfo jitPositionInfo = PositionInfo.wrap(
            uint256(
                parityTaxHook.exttload(
                    bytes32(uint256(JIT_LIQUIDITY_POSITION_LOCATION) + 2)
                    )
            )
        );
        bytes25 poolKeyLookUpPoolId = jitPositionInfo.poolId();
        PoolKey memory poolKey = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "poolKeys(bytes25)",
                     poolKeyLookUpPoolId
                )
            ),
            (PoolKey)
        );

        assert(PoolId.unwrap(poolKey.toId())== PoolId.unwrap(poolId));

        lpm.poolManager().donate(
            poolKey,
            uint256(uint128(jitTaxPaymentDelta.amount0())),
            uint256(uint128(jitTaxPaymentDelta.amount1())),
            bytes("")
        );        
    }

    function _calculateTaxPayment(BalanceDelta feeRevenueDelta) internal view returns(BalanceDelta taxPayment){
        uint24 taxRate;
        assembly("memory-safe"){
            taxRate := tload(TAX_RATE_SLOT)
        }

        if (taxRate == 0) {
           return BalanceDeltaLibrary.ZERO_DELTA;
        }

        // Ensure tax rate doesn't exceed Uniswap v4's maximum protocol fee (1000 pips = 0.1%)
        require(taxRate <= 1000, "Tax rate exceeds maximum protocol fee");

        unchecked {
            uint256 amount0TaxPayment = FullMath.mulDiv(
                SafeCast.toUint128(feeRevenueDelta.amount0()),
                1000000 - taxRate, // (1 - taxRate) as pips
                1000000 // 100% as pips (1,000,000)
            );
            
            uint256 amount1TaxPayment = FullMath.mulDiv(
                SafeCast.toUint128(feeRevenueDelta.amount1()),
                1000000 - taxRate, // (1 - taxRate) as pips
                1000000 // 100% as pips (1,000,000)
            );

            // Convert back to int128 and create BalanceDelta
            taxPayment = toBalanceDelta(
                int128(uint128(amount0TaxPayment)),
                int128(uint128(amount1TaxPayment))
            );
        }
    }

    function calculateOptimalTax(PoolId poolId,bytes memory data) external returns(uint24){
        uint24 taxRate = _calculateOptimalTax(poolId, data);
        assembly("memory-safe"){
            tstore(TAX_RATE_SLOT, taxRate)
        }
        return taxRate;
    }


    function accrueCredit(PoolId,bytes memory) external returns(uint256,uint256){

    }

    function _calculateOptimalTax(PoolId ,bytes memory) internal virtual returns(uint24){

    }

    function _accrueCredit(PoolId,bytes memory) internal virtual returns(uint256,uint256){

    }

    function onLiquidityCommitmment(PoolId ,bytes memory) external returns(bytes memory){

    }

    function _onLiquidityCommitmment(PoolId ,bytes memory) internal virtual returns(bytes memory){

    }

    function _remit(PoolId,FeeRevenueInfo) internal virtual{

    }



    function lpOracle() external view returns(ILPOracle){
        return _lpOracle;



    }
 
 
 
    function notifyBurn(uint256 tokenId, address owner, PositionInfo info, uint256 liquidity, BalanceDelta feesAccrued) external{}
    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) external{}
    function notifySubscribe(uint256 tokenId, bytes memory data) external{}
    function notifyUnsubscribe(uint256 tokenId) external{} 
    function _authorizeUpgrade(address newImplementation) internal virtual override{}
}