// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/utils/BaseHook.sol";
import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import "../types/LiquidityTimeCommitmentData.sol";
import {Position} from "v4-core/libraries/Position.sol";
import "v4-core/types/Currency.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "../libs/LiquidityManagerHelper.sol";
import "../types/LiquidityTimeCommitmentData.sol";
import "../interfaces/ILiquidityManager.sol";

error IncompatiblePositionTimeCommitments();
error UnauthorizedAction___MethodOnlyAvailableForPLP();
error UnauthorizedAction___MethodOnlyAvailableForJIT();
error UnsuccessfulLiquidityRouting___LPTypeNotSupported();

enum LPType {
    NONE, //NOTE: This is the default LP type, when LP does not have any position
    PLP, //NOTE: This is the PLP LP
    JIT //NOTE: This is the JIT LP
}

contract LiquidityTimeCommitmentHook is BaseHook {
    using SafeCast for *;
    using LiquidityManagerHelper for IPoolManager;
    using Hooks for IHooks;
    using CurrencySettler for Currency;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    using LiquidityTimeCommitmentDataLibrary for bytes;
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    using Position for *; // NOTE: This is mostly use to query positionKeys to them
    // associate position keys with time commitments

    mapping(bytes32 positionKey => LiquidityTimeCommitmentData)
        private liquidityPositionsTimeCommitmentData;

    mapping(bytes32 positionKey => LPType) private liquidityPositionType;

    mapping(bytes32 positionKey => mapping(LPType => ILiquidityManager))
        private liquidityManagers;

    //TODO: Is the sender on afterAddLiquidity the LP?
    // If ii is it eeasilly gfollows ..
    modifier onlyPLPAuthorized(
        address liquidityProvider,
        ModifyLiquidityParams memory liquidityParams
    ) {
        bytes32 liquidityPositionKey = liquidityProvider.calculatePositionKey(
            liquidityParams.tickLower,
            liquidityParams.tickUpper,
            liquidityParams.salt
        );
        if (liquidityPositionType[liquidityPositionKey] != LPType.PLP) {
            revert UnauthorizedAction___MethodOnlyAvailableForPLP();
        }
        _;
    }
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function getHookPermissions()
        public
        pure
        override(BaseHook)
        returns (Hooks.Permissions memory permissions)
    {
        permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true, //TODO: Is this more suitable to calcualate PLP's
            // tax revenue generated
            afterRemoveLiquidity: false, //TODO: Following with the above, this will alow PLP's
            // to realize their tax revenue generated
            beforeSwap: true, // NOTE: JIT determines to fullfill the swap and
            // what amounts, and deposits liquidity
            afterSwap: true, //NOTE: JIT withdraws the liquidity used to fullfill the swap
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false, //NOTE: This can be ENABLED in case the
            // underlying pool where JIT liquidity is being provided implements customCurve logic
            // but this is a feature rather than a requirement ...
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: true, //NOTE: This enables me the ability to transfer
            // JIT tax fee revenue to PLP's
            afterRemoveLiquidityReturnDelta: false
        });
    }
    //NOTE: At this point of the transaction the HookData has been already verified
    // to be correct or not, if not correct the transaction would have ended on the router
    //
    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override onlyPoolManager returns (bytes4) {
        //NOTE: This performs the checks that the hookData is valid
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = hookData
                .fromBytesToLiquidityTimeCommitmentData();

        bytes32 liquidityPositionKey = liquidityTimeCommitmentData
            .getPositionKey(params);

        TimeCommitment
            memory enteredTimeCommitment = liquidityTimeCommitmentData
                .getTimeCommitment();

        // NOTE: The time commitment is assumed to be valid because
        // it was checked before being entered
        TimeCommitment
            memory existingTimeCommitment = liquidityPositionsTimeCommitmentData[
                liquidityPositionKey
            ].getTimeCommitment();

        if (
            (!(existingTimeCommitment.isJIT) && enteredTimeCommitment.isJIT) ||
            (existingTimeCommitment.isJIT && !(enteredTimeCommitment.isJIT))
        ) {
            revert IncompatiblePositionTimeCommitments();
        }

        BalanceDelta liquidityDelta = poolManager.getPositionLiquidityDelta(
            key,
            params
        );

        (int128 liquidityOnCurrency0, int128 liquidityOnCurrency1) = (
            liquidityDelta.amount0(),
            liquidityDelta.amount1()
        );

        _settleLiquidityOnCurrencies(
            key,
            liquidityTimeCommitmentData,
            uint256(liquidityOnCurrency0.toUint128()),
            uint256(liquidityOnCurrency1.toUint128())
        );

        liquidityPositionsTimeCommitmentData[
            liquidityPositionKey
        ] = liquidityTimeCommitmentData;

        _routeLiquidity(
            key,
            liquidityPositionKey,
            uint256(liquidityOnCurrency0.toUint128()),
            uint256(liquidityOnCurrency1.toUint128()),
            liquidityTimeCommitmentData
        );

        return IHooks.beforeAddLiquidity.selector;
    }
    // TODO: This is guarded to PLP LP's, so we need to find a method
    // to associate the calldata with the timeCommitments
    // to guard this functions
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    )
        internal
        virtual
        override
        onlyPLPAuthorized(sender, params)
        onlyPoolManager
        returns (bytes4, BalanceDelta)
    {
        return
            _afterAddLiquidity(
                sender,
                key,
                params,
                delta,
                feesAccrued,
                hookData
            );
    }
    // TODO: This is guarded to JIT LP's, so we need to find a method
    // to associate the calldata with the timeCommitments
    // to guard this functions

    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24) {
        return _beforeSwap(sender, key, params, hookData);
    }

    // TODO: This is guarded to JIT LP's, so we need to find a method
    // to associate the calldata with the timeCommitments
    // to guard this functions
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    //NOTE: The initial liquidity request with the funds is assumed to
    // be brough by the EOA lp address, this is not accurate.
    function _settleLiquidityOnCurrencies(
        PoolKey memory poolKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData,
        uint256 liquidityOnCurrency0,
        uint256 liquidityOnCurrency1
    ) internal {
        poolKey.currency0.settle(
            poolManager,
            liquidityTimeCommitmentData.liquidityProvider,
            liquidityOnCurrency0,
            false // NOTE: We are not burning ERC6909 tokens
            // this is we are transfering ERC20 tokens
            // to the pool Manager
        );
        poolKey.currency1.settle(
            poolManager,
            liquidityTimeCommitmentData.liquidityProvider,
            liquidityOnCurrency1,
            false // NOTE: We are not burning ERC6909 tokens
            // this is we are transfering ERC20 tokens
            // to the pool Manager
        );
    }

    function _takeLiquidityOnCurrencies(
        PoolKey memory poolKey,
        address liquidityManager,
        uint256 liquidityOnCurrency0,
        uint256 liquidityOnCurrency1
    ) internal {
        poolKey.currency0.take(
            poolManager,
            liquidityManager,
            liquidityOnCurrency0,
            true //NOTE: Mint claim tokens from poolManager
            // to the liquidity operator
        );
        poolKey.currency1.take(
            poolManager,
            liquidityManager,
            liquidityOnCurrency1,
            true //NOTE: Mint claim tokens from poolManager
            // to the liquidity operator
        );
    }

    function _routeLiquidity(
        PoolKey memory key,
        bytes32 liquidityPositionKey,
        uint256 liquidityOnCurrency0,
        uint256 liquidityOnCurrency1,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal {
        //
        if (liquidityTimeCommitmentData.getTimeCommitment().isJIT) {
            liquidityPositionType[liquidityPositionKey] = LPType.JIT; //NOTE: This is a JIT LP
            _takeLiquidityOnCurrencies(
                key,
                address(liquidityManagers[liquidityPositionKey][LPType.JIT]),
                liquidityOnCurrency0,
                liquidityOnCurrency1
            );
        } else if (!liquidityTimeCommitmentData.getTimeCommitment().isJIT) {
            liquidityPositionType[liquidityPositionKey] = LPType.PLP; //NOTE: This is a PLP LP
            _takeLiquidityOnCurrencies(
                key,
                address(liquidityManagers[liquidityPositionKey][LPType.PLP]),
                liquidityOnCurrency0,
                liquidityOnCurrency1
            );
        } else {
            liquidityPositionType[liquidityPositionKey] = LPType.NONE; //NOTE: This is a NONE LP
            revert UnsuccessfulLiquidityRouting___LPTypeNotSupported();
        }
    }

    //NOTE: This has special guards, this function is provisional
    // only forr testing the flow of beforeSwap
    function setLPLiquidityManager(
        bytes32 positionKey,
        LPType lpType,
        ILiquidityManager liquidityManager
    ) external {
        liquidityManagers[positionKey][lpType] = liquidityManager;
    }

    function getLPLiquidityManager(
        bytes32 positionKey,
        LPType lpType
    ) external view returns (ILiquidityManager liquidityManager) {
        liquidityManager = liquidityManagers[positionKey][lpType];
    }
}
