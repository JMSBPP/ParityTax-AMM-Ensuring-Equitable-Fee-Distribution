// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {SharedStateSetUp} from "../shared/SharedStateSetUp.sol";
import {SwapSimulationLibraryHelper, SwapSimulation, SwapSimulationLibrary} from "./SwapSimulationTest.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Pool} from "v4-core/libraries/Pool.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {PoolTest} from "@uniswap/v4-core/test/libraries/Pool.t.sol";

uint256 constant JULY_8TH_TIMESTAMP = 1752012003;

contract SwapSimulationTest is Test, SharedStateSetUp {
    using BalanceDeltaLibrary for BalanceDelta;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    SwapSimulationLibraryHelper public swapSimulationLibraryHelper;
    PoolTest private poolTest;

    SwapSimulation public swapSimulation;

    function setUp() public {
        deployBaseProtocol(JULY_8TH_TIMESTAMP);
        //NOTE:
        // {tickLower: -120, tickUpper: 120, liquidityDelta: 1e18, salt: 0}
        (key, ) = initPoolAndAddLiquidity(
            currency0,
            currency1,
            IHooks(address(0x00)),
            Constants.FEE_MEDIUM,
            SQRT_PRICE_1_2
        );
        swapSimulationLibraryHelper = new SwapSimulationLibraryHelper();
        poolTest = new PoolTest();
        swapSimulation.manager = manager;
        swapSimulation.poolId = key.toId();
    }

    function test__fuzz__simulateSwapPLPLiquidity(
        Pool.SwapParams memory params,
        uint16 protocolFee0,
        uint16 protocolFee1
    ) external {
        poolTest.test_fuzz_swap(
            SQRT_PRICE_1_2,
            Constants.FEE_MEDIUM,
            protocolFee0,
            protocolFee1,
            params
        );
        (
            BalanceDelta swapDelta,
            uint256 amountToProtocol,
            uint24 swapFee,
            Pool.SwapResult memory result
        ) = swapSimulationLibraryHelper.simulateSwapPLPLiquidity(
                swapSimulation
            );
        console2.log("swapDelta", BalanceDelta.unwrap(swapDelta));
        console2.log("amountToProtocol", amountToProtocol);
        console2.log("swapFee", swapFee);
        console2.log("End Price", result.sqrtPriceX96);
        console2.log("End Tick", result.tick);
        console2.log("End Liquidity", result.liquidity);
    }
}
