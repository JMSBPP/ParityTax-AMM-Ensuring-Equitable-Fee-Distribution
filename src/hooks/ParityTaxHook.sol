// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v4-periphery/src/interface/IPositionManager.sol";
import "permit2/src/interfaces/IAllowanceTransfer.sol";
import "./base/HookCallableBaseHook.sol";
import "../types/TimeCommitment.sol";
import "v4-core/libraries/StateLibrary.sol";

contract ParityTaxHook is HookCallableBaseHook {
    using TimeCommitmentLibrary for *;

    IAllowanceTransfer private allowanceTransfer;
    IPositionManager private positionManager;

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes hookData
    ) internal override returns (bytes4, BalanceDelta) {
        //NOTE At this point the liquidity router owns the
        // delta owed to the PoolManager, thus the PoolManager
        // has a debit pending to be settled
        //1 Since afterAddLiquidityReturnDelta is enabled
        // we are transfering the delta to the ParityTaxHook
        BalanceDelta parityTaxLiquidityDelta = delta;

        TimeCommitment lpTimeCommitment = hookData.toTimeCommitment();
    }
}
