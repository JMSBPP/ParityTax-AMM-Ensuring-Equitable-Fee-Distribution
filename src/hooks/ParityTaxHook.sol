// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IParityTaxHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import "v4-core/libraries/Position.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-core/types/BeforeSwapDelta.sol";
import "v4-periphery/src/base/DeltaResolver.sol";
import "v4-core/libraries/CurrencyReserves.sol";
import {CurrencyLibrary} from "v4-core/types/Currency.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/libraries/TransientStateLibrary.sol";
import "v4-core/libraries/StateLibrary.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
import {NonzeroDeltaCount} from "v4-core/libraries/NonzeroDeltaCount.sol";

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {console} from "forge-std/Test.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
abstract contract ParityTaxHook is BaseHook, IParityTaxHook, TimelockController {
    using Position for address;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    using BalanceDeltaLibrary for BalanceDelta;
    using SafeCast for *;
    using StateLibrary for IPoolManager;
    bytes32 public constant JIT = keccak256("JIT");
    bytes32 public constant PLP = keccak256("PLP");


    modifier onlyJIT(address sender){
        _checkRole(JIT, sender);
        _;    
    }


    struct PLPPayload{
        address excecutor;
        uint256 delay;
    }

    constructor(
        IPoolManager _manager
    ) BaseHook(_manager) {
        _setupRole(PROPOSER_ROLE, poolManager);
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal virtual returns (bytes4){


        // This method is shared among all LP'S
        // thus here we need to clasify PLP's and JIT's
        //1. We ask the LP 

    }

    /// @inheritdoc BaseHook
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: fa;e,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }
}
