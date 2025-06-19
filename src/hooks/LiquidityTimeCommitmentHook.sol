// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/utils/BaseHook.sol";
import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import "../types/LiquidityTimeCommitmentData.sol";
import {Position} from "v4-core/libraries/Position.sol";
import "v4-core/types/Currency.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "../libs/LiquidityManagerHelper.sol";
import "../LiquidityTimeCommitmentHookStorageAdmin.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "v4-core/libraries/TransientStateLibrary.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
//=====PART OF THE ISSUE OF CurrencyNotSettled() ========
import "v4-core/libraries/NonzeroDeltaCount.sol";

event NonZeroDeltaCounts(uint256 counts);
// =====================================================

error IncompatiblePositionTimeCommitments();
error UnauthorizedAction___MethodOnlyAvailableForPLP();
error UnauthorizedAction___MethodOnlyAvailableForJIT();
error UnsuccessfulLiquidityRouting___LPTypeNotSupported();

contract LiquidityTimeCommitmentHook is
    BaseHook,
    LiquidityTimeCommitmentHookStorageAdmin
{
    using SafeCast for *;
    using LiquidityManagerHelper for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using StateLibrary for IPoolManager;
    using Hooks for IHooks;
    using CurrencySettler for Currency;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    using LiquidityTimeCommitmentDataLibrary for bytes;
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    using CurrencyDelta for *;
    using Position for *; // NOTE: This is mostly use to query positionKeys to them
    // associate position keys with time commitments

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
        if (
            _storage.getLiquidityPositionType(liquidityPositionKey) !=
            LPType.PLP
        ) {
            revert UnauthorizedAction___MethodOnlyAvailableForPLP();
        }
        _;
    }

    constructor(
        IPoolManager _manager,
        ILiquidityTimeCommitmentHookStorage _liquidityTimeCommitmentHookStorage
    )
        BaseHook(_manager)
        LiquidityTimeCommitmentHookStorageAdmin(
            _liquidityTimeCommitmentHookStorage
        )
    {}

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
            //=====PART OF THE ISSUE OF CurrencyNotSettled() ========
            // - NOTE: The true/false does not affect the error
            afterRemoveLiquidityReturnDelta: false
        });
    }
    //NOTE: At this point of the transaction the HookData has been already verified
    // to be correct or not, if not correct the transaction would have ended on the router
    //
    // function getPositionKey
    // TODO: There is potentially more usefull information needed to be broadcasted
    // to the blockchain ... TBD
    event LiquidityTimeCommitmentHookInitialized(
        bytes32 indexed liquidityPositionKey
    );
    event LiquidityAmountsToBeAdded(
        uint256 indexed liquidityOnCurrency0,
        uint256 indexed liquidityOnCurrency1
    );
    event DecodedHookDataSize(uint256 indexed size);
    event BalancesChecker(uint256 indexed balance0, uint256 indexed balance1);
    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override onlyPoolManager returns (bytes4) {
        //NOTE: This performs the checks that the hookData is valid
        emit DecodedHookDataSize(hookData.length);
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = hookData
                .fromBytesToLiquidityTimeCommitmentData();

        bytes32 liquidityPositionKey = liquidityTimeCommitmentData
            .getPositionKey(params);
        // NOTE: The time commitment is assumed to be valid because
        // it was checked before being entered
        TimeCommitment
            memory enteredTimeCommitment = liquidityTimeCommitmentData
                .getTimeCommitment();

        //NOTE: If this is the first time adding liquidty with commitment
        // the existingTimeCommitment is null, this is a special case then.
        //This can be checked with try/catch becasue  all timeCommitments
        // are validated before arriving here ...

        try _storage.getTimeCommitment(liquidityPositionKey) returns (
            TimeCommitment memory existingTimeCommitment
        ) {
            if (
                existingTimeCommitment.isJIT != enteredTimeCommitment.isJIT ||
                !(existingTimeCommitment.isJIT) !=
                !(enteredTimeCommitment.isJIT)
            ) {
                revert IncompatiblePositionTimeCommitments();
            }
        } catch (bytes memory) {
            //TODO: The reason is specifically decoded to the error
            // on the TimeCommitment library
            // InvalidRawData___RawDataDoesNotDecodeToTimeCommitment()
            emit LiquidityTimeCommitmentHookInitialized(liquidityPositionKey);
        }
        _storage.setLiquidityTimeCommitmentData(
            liquidityPositionKey,
            liquidityTimeCommitmentData
        );
        // From already verified timeCommitment we have
        // set the LPType enum:
        // ==>
        LPType lpType = enteredTimeCommitment.isJIT ? LPType.JIT : LPType.PLP;
        //Given this lpType and the position key we can query the
        // liquidity manager associated with the position and the LPType
        ILiquidityTimeCommitmentManager liquidityManager = _storage
            .getLiquidityManager(liquidityPositionKey, lpType);
        // In order to settle balances on the afterAddLiquidity function
        // we need to store this in transient storage so it can be queried
        // in the afterAddLiquidity function,to do so
        _storeLiquidityManagerOnTransientStorage(liquidityManager);
        _storeLiquidityPositionKeyOnTransientStorage(liquidityPositionKey);
        // TODO: Now that we have defined the positionKey of the liquidity
        // provider and now if it is JIT or PLP with it's timeCommitment
        // and we know this is addingLiquidity action.
        // The PoolManager will do this:
        // key.hooks.beforeModifyLiquidity(key, params, hookData);

        //BalanceDelta principalDelta;
        //     (principalDelta, feesAccrued) = pool.modifyLiquidity(
        //         Pool.ModifyLiquidityParams({
        //             owner: msg.sender,
        //             tickLower: params.tickLower,
        //             tickUpper: params.tickUpper,
        //             liquidityDelta: params.liquidityDelta.toInt128(),
        //             tickSpacing: key.tickSpacing,
        //             salt: params.salt
        //         })
        //     );
        // First for feesAccrued:: ==>
        // {
        //  (uint256 dFee0, uint256 dFee1) = getFeeGrowthInside(self, tickLower, tickUpper);
        //  Position.State storage position = self.positions.get(
        //                                                      params.owner,
        //                                                      tickLower,
        //                                                      tickUpper,
        //                                                      params.salt);
        // (uint256 fees0, uint256 fees1) = position.update(
        //                                                  liquidityDelta,
        //                                                  dfee0,
        //                                                  dfee1);
        //
        // feesAccrued = toBalanceDelta(fees0.toInt128(), fees1.toInt128());
        //}
        // Now for principalDelta:: ==>
        // {
        //      (int24 tick, uint160 sqrtPriceX96) = (_slot0.tick(),
        //                                            _slot0.sqrtPriceX96());
        // if (tick < tickLower) {
        //     // current tick is below the passed range; liquidity can only become in range by crossing from left to
        //     // right, when we'll need _more_ currency0 (it's becoming more valuable) so user must provide it
        //     principalDelta = toBalanceDelta(
        //                                     SqrtPriceMath.getAmount0Delta(
        //                                                                    TickMath.getSqrtPriceAtTick(tickLower),
        //                                                                    TickMath.getSqrtPriceAtTick(tickUpper),
        //                                                                     liquidityDelta
        //                                                                   ).toInt128()
        //                                                                   ,
        //                                                                   0
        //                                     );
        // } else if (tick < tickUpper) {
        //     principalDelta = toBalanceDelta(
        //                                     SqrtPriceMath.getAmount0Delta(
        //                                                                   sqrtPriceX96,
        //                                                                   TickMath.getSqrtPriceAtTick(tickUpper),
        //                                                                    liquidityDelta
        //                                                                   ).toInt128()
        //                                                                    ,
        //                                     SqrtPriceMath.getAmount1Delta(
        //                                                                   TickMath.getSqrtPriceAtTick(tickLower),
        //                                                                   sqrtPriceX96,
        //                                                                   liquidityDelta
        //                                                                   ).toInt128()
        //                                     );

        // self.liquidity = LiquidityMath.addDelta(self.liquidity, principalDelta);
        // } else {
        //     // current tick is above the passed range; liquidity can only become in range by crossing from right to
        //     // left, when we'll need _more_ currency1 (it's becoming more valuable) so user must provide it
        //     principalDelta = toBalanceDelta(
        //                                      0
        //                                      ,
        //                                      SqrtPriceMath.getAmount1Delta(
        //                                                                    TickMath.getSqrtPriceAtTick(tickLower),
        //                                                                    TickMath.getSqrtPriceAtTick(tickUpper),
        //                                                                     liquidityDelta
        //                                                                   ).toInt128()
        //                                      );
        // }
        //
        // }
        // ==========================>
        // callerDelta = principalDelta + feesAccrued;
        // Notice in this case msg.sender =liquidityTimeCommitmentRouter
        // Therefore this is what get's returned to the poolManager before
        // it excecutes afterAddLiquidity

        // TODO: Right after _routingLiquidity we want to retreive the deltas
        // from transientStorage, for this one can use the NonZeroDelta library
        //1. Create a branch specialized for this issue, with the code there ...
        //2. Read the non-zero deltas from transientStorage
        // 2.1 Read the counts.
        // ========FOR-DEBUGIING PURPOSES======
        // NOTE: This is not part of the core logic.
        // =====Only for testing purposes=====
        (uint256 balance0, uint256 balance1) = (
            key.currency0.balanceOf(address(poolManager)),
            key.currency1.balanceOf(address(poolManager))
        );
        emit BalancesChecker(balance0, balance1);
        return IHooks.beforeAddLiquidity.selector;
    }

    // TODO: This is guarded to PLP LP's, so we need to find a method
    // to associate the calldata with the timeCommitments
    // to guard this functions
    event AfterAddLiquidityDeltaCounts(uint256 count);
    event LiquidityDeltas(int256 onX, int256 onY);
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
        // onlyPLPAuthorized(sender, params)
        onlyPoolManager
        returns (bytes4, BalanceDelta)
    {
        // TODO: Because we have the afterAddLiquidityReturDelta we have the
        // the following case
        // (callerDelta, hookDelta) = key.hooks.afterModifyLiquidity(key, params, callerDelta, feesAccrued, hookData);
        // (hookDelta != BalanceDeltaLibrary.ZERO_DELTA)
        // _accountPoolBalanceDelta(key, hookDelta, address(this));
        //    _accountDelta(key.currency0, delta.amount0(), address(this));
        //     _accountDelta(key.currency1, delta.amount1(), address(this));
        // ==> _accountDelta(currency, delta.amountX(), address(this))
        // ====>         if (delta == 0) return;

        //            (int256 previous, int256 next) = currency.applyDelta(
        //                                                                 address(this),
        //                                                                 hookDelta);
        //
        //              if (next == 0) {
        //                               NonzeroDeltaCount.decrement();
        //               } else if (previous == 0) {
        //                               NonzeroDeltaCount.increment();
        //               }
        // Where we need to build our hookDelta
        // Our hookDelta is how much we want to send to the liquidityManager
        // associated with the positionKey
        // 1. so we query the liquidityManager from transientStorage
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = hookData
                .fromBytesToLiquidityTimeCommitmentData();

        (
            bytes32 liquidityPositionKey,
            ILiquidityTimeCommitmentManager liquidityManager
        ) = (
                _getLiquidityPositionKeyFromTransientStorage(),
                _getLiquidityManagerFromTransientStorage()
            );
        (uint256 balance0, uint256 balance1) = (
            key.currency0.balanceOf(address(this)),
            key.currency1.balanceOf(address(this))
        );
        emit BalancesChecker(balance0, balance1);

        // 2. We want the liquidityDelta to be the amounts to be sent
        // to the liquidityManager
        //
        // CurrencyDelta has the getDelta(Currency, address deltaOwner) function
        // which retrieves the deltaCurrency of the owner of the delta
        // to implement this option we need to know who is the owner of the
        // delta at this point
        // Since _accountToDelta has not been called yet at this point
        // we think the deltaOwner is the poolManager let's verify that
        // Looks like the deltaOwner is the router ...
        // (int256 liquidityDeltaCurrency0, int256 liquidityDeltaCurrency1) = (
        //     key.currency0.getDelta(deltaOwner),
        //     key.currency1.getDelta(deltaOwner)
        // );

        // emit LiquidityDeltas(liquidityDeltaCurrency0, liquidityDeltaCurrency1);
        return (
            IHooks.afterAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
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
            _storage.setLiquidityPositionType(liquidityPositionKey, LPType.JIT); //NOTE: This is a JIT LP
            _takeLiquidityOnCurrencies(
                key,
                address(
                    _storage.getLiquidityManager(
                        liquidityPositionKey,
                        LPType.JIT
                    )
                ),
                liquidityOnCurrency0,
                liquidityOnCurrency1
            );
        } else if (!liquidityTimeCommitmentData.getTimeCommitment().isJIT) {
            _storage.setLiquidityPositionType(liquidityPositionKey, LPType.PLP); //NOTE: This is a PLP LP
            _takeLiquidityOnCurrencies(
                key,
                address(
                    _storage.getLiquidityManager(
                        liquidityPositionKey,
                        LPType.PLP
                    )
                ),
                liquidityOnCurrency0,
                liquidityOnCurrency1
            );
        } else {
            _storage.setLiquidityPositionType(
                liquidityPositionKey,
                LPType.NONE
            ); //NOTE: This is a NONE LP
            revert UnsuccessfulLiquidityRouting___LPTypeNotSupported();
        }
    }
}
