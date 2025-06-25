// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v4-periphery/src/base/SafeCallback.sol";
import "../types/LPTimeCommitment.sol";
import "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "v4-core/types/BalanceDelta.sol";
import "../hooks/interfaces/ILiquidityOperator.sol";

import "../interfaces/ILiquidityOperatorsRegistry.sol";

import "@uniswap/v4-core/test/utils/Constants.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/libraries/StateLibrary.sol";
import "v4-core/libraries/TransientStateLibrary.sol";

error IncompatibleLPTypes__LPTypeMustBeSameAsExisting();
error InvalidLPAction__TimeCommitmentNotExpired();
contract LPTypeLiquidityRouter is SafeCallback {
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    address private liquidityOperatorsRegistryAddress;

    constructor(IPoolManager _poolManager) SafeCallback(_poolManager) {}

    //TODO: This needs to verify that the address is actually correct
    // this can be done with Initializers ...
    function setLiquidityOperatorsRegistryAddress(
        address _liquidityOperatorsRegistryAddress
    ) external {
        liquidityOperatorsRegistryAddress = _liquidityOperatorsRegistryAddress;
    }

    //TODO: This function can only be called once there is a valid
    // liquidityOperatorsRegistryAddress already set ...

    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory liquidityParams,
        bytes memory hookData
    )
        public
        payable
        returns (
            // bool settleUsingBurn,
            // bool takeClaims
            BalanceDelta delta
        )
    {
        // NOTE: For adding liquidity the LP will be creating/updating
        // a LP position
        address liquidityProvider = msg.sender;
        if (liquidityParams.liquidityDelta > 0) {
            //2.hookData needs to decode to a LPTimeCommitment
            LPTimeCommitment memory enteredLpTimeCommitment = abi.decode(
                hookData,
                (LPTimeCommitment)
            );

            ILiquidityOperatorsRegistry(liquidityOperatorsRegistryAddress)
                .setLPTimeCommitment(
                    liquidityProvider,
                    enteredLpTimeCommitment
                );
            //NOTE: At this point the liquidity Provider has specified the
            // time commitment associated with his addLiquidity
            // position and the liquidityOperator that will be managing
            // this position.

            delta = abi.decode(
                //                                                 takeClaims
                poolManager.unlock(
                    abi.encode(
                        key,
                        liquidityParams,
                        liquidityProvider,
                        enteredLpTimeCommitment
                    )
                ),
                (BalanceDelta)
            );

            //NOTE: If the lp is looking to remove liquidity from the operators
            // we need to:
        } else if (liquidityParams.liquidityDelta < 0) {
            // Verify that the LP time commitment has indeed expired, this is:
            LPTimeCommitment
                memory existingLPTimeCommitment = ILiquidityOperatorsRegistry(
                    liquidityOperatorsRegistryAddress
                ).getLPTimeCommitment(liquidityProvider);
            if (existingLPTimeCommitment.endingBlock <= block.number) {
                //NOTE: At this point we can do the callback to allow for
                // liquidity removal from the operator
                // Therefore what follows is:
                // 1. unlock the manager for allowing the liquitty addition using takeClaims
                delta = abi.decode(
                    //
                    poolManager.unlock(
                        abi.encode(
                            key,
                            liquidityParams,
                            liquidityProvider,
                            existingLPTimeCommitment
                        )
                    ),
                    (BalanceDelta)
                );
            } else {
                revert InvalidLPAction__TimeCommitmentNotExpired();
            }
        }
    }

    function _unlockCallback(
        bytes calldata data
    ) internal override returns (bytes memory) {
        //NOTE:
        // 1. Allow liquidity to be added
        (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory params,
            address liquidityProvider,
            LPTimeCommitment memory enteredLpTimeCommitment
        ) = abi.decode(
                data,
                (PoolKey, ModifyLiquidityParams, address, LPTimeCommitment)
            );

        (BalanceDelta liquidityDelta, ) = poolManager.modifyLiquidity(
            poolKey,
            params,
            abi.encode(enteredLpTimeCommitment)
        );

        if (params.liquidityDelta > 0) {
            {
                poolManager.sync(poolKey.currency0);
                poolManager.sync(poolKey.currency1);
                poolManager.settleFor(address(this));
            }
        }

        return abi.encode(liquidityDelta);
    }
}
