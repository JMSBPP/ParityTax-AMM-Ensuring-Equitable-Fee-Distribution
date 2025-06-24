// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v4-periphery/src/utils/BaseHook.sol";
import "../types/LPTimeCommitment.sol";
contract LiquidityTimeCommitmentHook is BaseHook {
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function getHookPermissions()
        public
        pure
        virtual
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true, //NOTE: This allow us to delegate calll to the
                // correspoding liquidityOperator
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false, //TODO: This
                // can be updated to true if the pool has
                // custom curve
                afterSwapReturnDelta: true, // TODO:
                // this is applied by the tax controller
                // to charge the tax over the trading fees
                //
                afterAddLiquidityReturnDelta: false, //TODO: This needs to be enabled to
                // be conssitent with the LiquidityTimeCommitment hook
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BalanceDelta) {
        //1.  Decode the underlying liquidityTimeCommitment from the hookData
        LPTimeCommitment memory enteredLpTimeCommitment = abi.decode(
            hookData,
            (LPTimeCommitment)
        );
        // NOTE: At this point the poolManager has a debit
        // of delta  coming from the liquidityProvider
        // This debit is now to be transfered to the liquidityTime
        // CommitmentHook
        BalanceDelta liquidityTimeCommitmentHookDelta = delta;
        {
            (
                uint256 liquidityAddedOnCurrency0,
                uint256 liquidityAddedOnCurrency1
            ) = (
                    uint256(
                        int256(-liquidityTimeCommitmentHookDelta.amount0())
                    ),
                    uint256(int256(-liquidityTimeCommitmentHookDelta.amount1()))
                );
            poolManager.mint(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency0.toId(),
                liquidityAddedOnCurrency0
            );
            poolManager.mint(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency1.toId(),
                liquidityAddedOnCurrency1
            );
            //NOTE: In order to allow the poolManager to credit the
            //liquidityOperator to settle the liquidity added by the liquidity operator
            // we need to make approve the liquidity to the liquidityOperator
            poolManager.approve(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency0.toId(),
                liquidityAddedOnCurrency0
            );
            poolManager.approve(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency1.toId(),
                liquidityAddedOnCurrency1
            );
        }
        {
            //NOTE: With the amounts debited to the right liquidityOperator
            // we can now forward the the afterAddLiquidity request
            // to the right liquidityOperator using delegatecall

            // This also guarantees that the msg.sender = poolManager
            (bool ok, bytes memory encodedRes) = address(
                enteredLpTimeCommitment.liquidityOperator
            ).delegatecall(
                    abi.encodeWithSignature(
                        "function afterAddLiquidity(address,PoolKey memory ,ModifyLiquidityParams memory ,BalanceDelta delta,BalanceDelta,bytes calldata) external onlyPoolManager",
                        sender,
                        key,
                        params,
                        delta,
                        feesAccrued,
                        hookData
                    )
                );
            //TODO: Verify the delegate call is successfull
            if (ok) {
                (bytes4 selector, BalanceDelta liquidityOperatorDelta) = abi
                    .decode(encodedRes, (bytes4, BalanceDelta));
                //NOTE: This liquidityOperatorDelta includes the deltas with the tax added or removed
                // to the lp therefore we can settle the balances

                // Sync the reserves of the pool
                poolManager.sync(key.currency0);
                poolManager.sync(key.currency1);
                // credit the liquidityOperator
                poolManager.burn(
                    address(enteredLpTimeCommitment.liquidityOperator),
                    key.currency0.toId(),
                    uint256(int256(-liquidityOperatorDelta.amount0()))
                );
                poolManager.burn(
                    address(enteredLpTimeCommitment.liquidityOperator),
                    key.currency1.toId(),
                    uint256(int256(-liquidityOperatorDelta.amount1()))
                );

                return (selector, liquidityOperatorDelta);
            }
        }

        return (
            IHooks.afterAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
    }
}
