// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../src/types/LPTimeCommitment.sol";
import "../../../src/hooks/JITHook.sol";
import "../../../src/hooks/PLPLiquidityOperator.sol";
import "../../utils/InvalidOperator.sol";

uint160 constant LIQUIDITY_TIME_COMMITMENT_FLAGS = uint160(
    Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
);

uint160 constant JIT_HOOK_FLAGS = uint160(
    Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG
);

uint160 constant PLP_OPERATOR_FLAGS = uint160(
    Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
);
uint160 constant INVALID_OPERATOR_FLAGS = uint160(Hooks.BEFORE_INITIALIZE_FLAG);
enum OPERATOR_TYPE {
    INVALID,
    JIT,
    PLP
}

struct OperatorsDeployersData {
    uint160 flags;
    bytes operatorCreationCode;
    bytes operatorConstructorArgs;
    bytes32 salt;
    bytes operatorCreationCodeWithArgs;
}
library OperatorsDeployersDataLibrary {
    function setOperatorsDeployersData(
        OPERATOR_TYPE operatorType,
        bytes memory operatorConstructorArgs,
        bytes32 salt
    )
        internal
        pure
        returns (OperatorsDeployersData memory operatorsDeployersData)
    {
        operatorsDeployersData = OperatorsDeployersData({
            flags: setOperatorFlags(operatorType),
            operatorCreationCode: setOperatorCreationCode(operatorType),
            operatorConstructorArgs: operatorConstructorArgs,
            salt: salt,
            operatorCreationCodeWithArgs: setOperatorCreationCodeWithArgs(
                operatorType,
                operatorConstructorArgs
            )
        });
    }

    function setOperatorConstructorArgs(
        OPERATOR_TYPE operatorType,
        bytes memory constructorArgs
    ) internal pure returns (bytes memory operatorConstructorArgs) {
        operatorConstructorArgs = constructorArgs;
    }

    function setOperatorCreationCodeWithArgs(
        OPERATOR_TYPE operatorType,
        bytes memory operatorConstructorArgs
    ) internal pure returns (bytes memory operatorCreationCodeWithArgs) {
        operatorCreationCodeWithArgs = abi.encodePacked(
            setOperatorCreationCode(operatorType),
            operatorConstructorArgs
        );
    }
    function setOperatorFlags(
        OPERATOR_TYPE operatorType
    ) internal pure returns (uint160 flags) {
        uint256 plp = PLP_OPERATOR_FLAGS;
        uint256 jit = JIT_HOOK_FLAGS;
        uint256 _invalid = INVALID_OPERATOR_FLAGS;
        assembly ("memory-safe") {
            switch operatorType
            case 0 {
                flags := _invalid
            }
            case 1 {
                flags := jit
            }
            case 2 {
                flags := plp
            }
            default {
                revert(0, 0)
            }
        }
    }

    function setOperatorCreationCode(
        OPERATOR_TYPE operatorType
    ) internal pure returns (bytes memory creationCode) {
        bytes memory invalidCode = type(InvalidOperator).creationCode;
        bytes memory jitCode = type(JITHook).creationCode;
        bytes memory plpCode = type(PLPLiquidityOperator).creationCode;

        assembly ("memory-safe") {
            switch operatorType
            case 0 {
                creationCode := invalidCode
            }
            case 1 {
                creationCode := jitCode
            }
            case 2 {
                creationCode := plpCode
            }
            default {
                revert(0, 0)
            }
        }
    }
}
