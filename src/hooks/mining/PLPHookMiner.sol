// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "v4-periphery/src/utils/HookMiner.sol";
import "../PLPLiquidityOperator.sol";
import "v4-core/libraries/Hooks.sol";

library PLPHookMiner {
    using HookMiner for address;
    using Hooks for IHooks;

    uint160 internal constant _PLPHOOK_AFTER_ADD_LIQUIDITY_FLAG =
        Hooks.AFTER_ADD_LIQUIDITY_FLAG;
    //@dev Initialized at 0 by the default
    // WARNING: This is useless if not set befault

    uint160 internal constant _PLP_HOOK_FLAGS =
        uint160(_PLPHOOK_AFTER_ADD_LIQUIDITY_FLAG);
    function _setContractDeployer(
        address deployer
    ) internal pure returns (address _deployer) {
        _deployer = deployer;
    }

    function _setPoolManagerImplementationAddress(
        IPoolManager _manager
    ) internal pure returns (IPoolManager __manager) {
        __manager = _manager;
    }

    function _getEncodedConstructorArgs(
        IPoolManager _manager
    ) internal pure returns (bytes memory encodedCosntructorArgs) {
        encodedCosntructorArgs = abi.encode(
            _setPoolManagerImplementationAddress(_manager)
        );
    }

    function _getPLPOperatorHookAddressAndSalt(
        IPoolManager _manager,
        address deployer
    ) internal view returns (address plpHookAddress, bytes32 plpHookSalt) {
        bytes memory creationCode = type(PLPLiquidityOperator).creationCode;
        (plpHookAddress, plpHookSalt) = _setContractDeployer(deployer).find(
            _PLP_HOOK_FLAGS,
            creationCode,
            _getEncodedConstructorArgs(_manager)
        );
    }
}
