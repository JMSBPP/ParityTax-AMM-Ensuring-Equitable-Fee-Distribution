// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "v4-periphery/src/utils/HookMiner.sol";
import "../JITLiquidityOperator.sol";
import "v4-core/libraries/Hooks.sol";

library JITHookMiner {
    using HookMiner for address;
    using Hooks for IHooks;
    //TODO: We need to find appropiate addresses
    // for the JITHooks, this are indexed somewhat
    // by the salt
    //1. What are the flags that this hooks
    //uses
    uint160 internal constant _JITHOOK_BEFORE_SWAP_FLAG =
        Hooks.BEFORE_SWAP_FLAG;
    uint160 internal constant _JITHOOK_AFTER_SWAP_FLAG = Hooks.AFTER_SWAP_FLAG;
    //@dev Initialized at 0 by the default
    // WARNING: This is useless if not set befault

    uint160 internal constant _JIT_HOOK_FLAGS =
        uint160(_JITHOOK_BEFORE_SWAP_FLAG | _JITHOOK_AFTER_SWAP_FLAG);
    //2. We need the constructor arguments of the
    // the hook INITIALLY subject to change, this is
    // only the poolManager.

    // For this we need the PoolManager reference address,

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

    function _getJITOperatorHookAddressAndSalt(
        IPoolManager _manager,
        address deployer
    ) internal view returns (address jitHookAddress, bytes32 jitHookSalt) {
        bytes memory creationCode = type(JITLiquidityOperator).creationCode;
        (jitHookAddress, jitHookSalt) = _setContractDeployer(deployer).find(
            _JIT_HOOK_FLAGS,
            creationCode,
            _getEncodedConstructorArgs(_manager)
        );
    }

    // We now have the poolManage and the deployer o the JITHook
    // operator and the flags
}
