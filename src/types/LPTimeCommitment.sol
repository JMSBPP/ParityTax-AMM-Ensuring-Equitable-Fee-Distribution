// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../hooks/interfaces/ILiquidityOperator.sol";
import "v4-core/libraries/Hooks.sol";

bytes32 constant JIT_OPERATOR_PERMISSIONS = keccak256(
    abi.encode(
        Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
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
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        })
    )
);

bytes32 constant PLP_OPERATOR_PERMISSIONS = keccak256(
    abi.encode(
        Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true, // NOTE: This will be implemented
            // to distrinute fee income using USDC streams
            // plugin with circle throug the taxController
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        })
    )
);

error InvalidLPType___LPTypeMustBePLPOrJIT();
error InvalidLPType___LPTypeMustAlradyExist();
error UnsuccessfullLowLevelCall();
error InvalidOperator___LPTypeMustBeCompatibleWithOperatorType();
error InvalidTimeCommitment__BlockAlreadyPassed();
error InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock();
error InvalidLPType___LPTypeMustBeJIT();
error InvalidLPType___LPTypeMustBePLP();

error InvalidJITTimeCommitment__StartingBlockMustBeEqualToEndingBlock();
error InvalidPLPTimeCommitment__EndingBlockMustBeStrictlyGreaterThanStartingBlock();

enum LPType {
    NONE,
    JIT,
    PLP
}

struct LPTimeCommitment {
    ILiquidityOperator liquidityOperator;
    LPType lpType;
    uint256 startingBlock;
    uint256 endingBlock;
}

library LPTimeCommitmentLibrary {
    function setJITLpTimeCommitment(
        uint256 blockToCommitLiquidity,
        ILiquidityOperator liquidityOperator
    ) internal returns (LPTimeCommitment memory) {
        LPTimeCommitment memory timeCommitment = LPTimeCommitment({
            liquidityOperator: liquidityOperator,
            lpType: LPType.JIT,
            startingBlock: blockToCommitLiquidity,
            endingBlock: blockToCommitLiquidity
        });

        {
            validateJITTimeCommitment(timeCommitment);
            validateLPTypeOperator(timeCommitment);
        }

        return timeCommitment;
    }

    function setPLPLpTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        ILiquidityOperator liquidityOperator
    ) internal returns (LPTimeCommitment memory) {
        LPTimeCommitment memory timeCommitment = LPTimeCommitment({
            liquidityOperator: liquidityOperator,
            lpType: LPType.PLP,
            startingBlock: startingBlock,
            endingBlock: endingBlock
        });

        {
            validatePLPTimeCommitment(timeCommitment);
            validateLPTypeOperator(timeCommitment);
        }

        return timeCommitment;
    }

    function validateTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) internal view {
        if (enteredTimeCommitment.startingBlock < block.number) {
            revert InvalidTimeCommitment__BlockAlreadyPassed();
        }
        if (
            enteredTimeCommitment.endingBlock <
            enteredTimeCommitment.startingBlock
        ) {
            revert InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock();
        }
    }

    function validateJITTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) internal view {
        {
            validateLPType(enteredTimeCommitment);
            if (enteredTimeCommitment.lpType != LPType.JIT) {
                revert InvalidLPType___LPTypeMustBeJIT();
            }
        }

        {
            validateTimeCommitment(enteredTimeCommitment);
            if (
                enteredTimeCommitment.startingBlock <
                enteredTimeCommitment.endingBlock
            ) {
                revert InvalidJITTimeCommitment__StartingBlockMustBeEqualToEndingBlock();
            }
        }
    }
    function validatePLPTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) internal view {
        {
            validateLPType(enteredTimeCommitment);
            if (enteredTimeCommitment.lpType != LPType.PLP) {
                revert InvalidLPType___LPTypeMustBePLP();
            }
        }

        {
            validateTimeCommitment(enteredTimeCommitment);
            if (
                enteredTimeCommitment.startingBlock ==
                enteredTimeCommitment.endingBlock
            ) {
                revert InvalidPLPTimeCommitment__EndingBlockMustBeStrictlyGreaterThanStartingBlock();
            }
        }
    }
    function validateLPType(
        LPTimeCommitment memory enteredTimeCommitment
    ) internal pure {
        if (enteredTimeCommitment.lpType == LPType.NONE)
            revert InvalidLPType___LPTypeMustBePLPOrJIT();
    }
    //WARNING: This is to be improved the current checkers only validate
    // hook permissions, in practice one would have to do further checks
    // to ensure is indeed a JIT/PLPHook implementation
    function validateLPTypeOperator(
        LPTimeCommitment memory enteredTimeCommitment
    ) internal {
        validateLPType(enteredTimeCommitment);
        //NOTE: If the enteredTimeCommitment.lpType == LPType.JIT
        // then we compare the hook permissiones for JITHooks
        (bool ok, bytes memory res) = address(
            enteredTimeCommitment.liquidityOperator
        ).call(abi.encodeWithSignature("getHookPermissions()"));
        if (!ok) {
            revert UnsuccessfullLowLevelCall();
        }
        bytes32 operatorPermissions = keccak256(res);

        // NOTE: When asked for the permissions if the LPType is
        // PLP then the hook permissions are those of the PLPHook
        if (enteredTimeCommitment.lpType == LPType.JIT) {
            if (operatorPermissions != JIT_OPERATOR_PERMISSIONS) {
                revert InvalidOperator___LPTypeMustBeCompatibleWithOperatorType();
            }
        } else if (enteredTimeCommitment.lpType == LPType.PLP) {
            if (operatorPermissions != PLP_OPERATOR_PERMISSIONS) {
                revert InvalidOperator___LPTypeMustBeCompatibleWithOperatorType();
            }
        }
    }
}
