// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {MockJITResolver} from "../mocks/MockJITResolver.sol";
import {MockPLPResolver} from "../mocks/MockPLPResolver.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {
    PosmTestSetup,
    IWETH9,
    IAllowanceTransfer
} from "@uniswap/v4-periphery/test/shared/PosmTestSetup.sol";

import {Test} from "forge-std/Test.sol";



contract LiquidityResolversSetUp is PosmTestSetup{

    MockJITResolver jitResolver;
    MockPLPResolver plpResolver;





    function deployAndApproveResolvers(
        IPoolManager _poolManager,
        IPositionManager _lpm
    ) internal {
        jitResolver = new MockJITResolver(
            manager,
            lpm
        );
        plpResolver = new MockPLPResolver(
            manager,
            lpm    
        );
        approvePosmFor(address(jitResolver));
        approvePosmFor(address(jitResolver));
        approvePosmFor(address(plpResolver));
        approvePosmFor(address(plpResolver));

    }


    function fundResolvers() internal{
        seedBalance(address(jitResolver));
        seedBalance(address(plpResolver));
    }



}


        