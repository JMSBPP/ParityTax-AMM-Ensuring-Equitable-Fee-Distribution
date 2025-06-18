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
}
