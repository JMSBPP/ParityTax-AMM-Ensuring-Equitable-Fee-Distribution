// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityTimeCommitmentHookStorage.sol";

contract LiquidityTimeCommitmentHookStorageAdmin {
    ILiquidityTimeCommitmentHookStorage internal _storage;
    constructor(
        ILiquidityTimeCommitmentHookStorage _liquidityTimeCommitmentHookStorage
    ) {
        setLiquidityTimeCommitmentHookStorage(
            _liquidityTimeCommitmentHookStorage
        );
    }

    function setLiquidityTimeCommitmentHookStorage(
        ILiquidityTimeCommitmentHookStorage _liquidityTimeCommitmentHookStorage
    ) internal {
        _storage = _liquidityTimeCommitmentHookStorage;
    }

    function _storeLiquidityManagerOnTransientStorage(
        ILiquidityTimeCommitmentManager liquidityManager
    ) internal {
        _storage.storeLiquidityManagerOnTransientStorage(liquidityManager);
    }

    function _getLiquidityManagerFromTransientStorage()
        internal
        view
        returns (ILiquidityTimeCommitmentManager)
    {
        return _storage.getLiquidityManagerFromTransientStorage();
    }

    function _storeLiquidityPositionKeyOnTransientStorage(
        bytes32 liquidityPositionKey
    ) internal {
        _storage.storeLiquidityPositionKeyOnTransientStorage(
            liquidityPositionKey
        );
    }

    function _getLiquidityPositionKeyFromTransientStorage()
        internal
        view
        returns (bytes32)
    {
        return _storage.getLiquidityPositionKeyFromTransientStorage();
    }
}
