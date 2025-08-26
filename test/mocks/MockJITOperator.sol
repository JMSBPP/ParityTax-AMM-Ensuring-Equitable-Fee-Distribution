// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";
import {IJITOperator} from "../../src/interfaces/IJITOperator.sol";
import {IAllowanceTransfer} from "@uniswap/v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";

import {
    PositionInfo,
    PositionInfoLibrary
} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Permit2Forwarder} from "@uniswap/v4-periphery/src/base/Permit2Forwarder.sol";
// For debuggging

import {console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract MockJITOperator is LiquidityOperations, IJITOperator{
    using PositionInfoLibrary for PositionInfo;
    using PoolIdLibrary for PoolKey;
    using Address for address;

    using Planner for Plan;

    IAllowanceTransfer _permit2;
    
    constructor(
        address _positionManager,
        address __permit2
    ){
        lpm = IPositionManager(_positionManager);
        _permit2 = IAllowanceTransfer(__permit2);
    }


    function positionManager() external view returns (IPositionManager){
        return lpm;
    }


    function permit2() external view returns(address){
        return address(_permit2);
    }



    function addJITLiquidity(
        PoolKey calldata poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint128 addLiquidityDelta,
        address recipient,
        bytes calldata hookData
        
    ) external {
        console2.log(uint256(addLiquidityDelta));
        mintWhenUnlocked(
            PositionConfig({
                poolKey: poolKey,
                tickLower: tickLower < tickUpper ? tickLower: tickUpper,
                tickUpper: tickLower < tickUpper ? tickUpper: tickLower
            }),
            uint256(addLiquidityDelta),
            recipient,
            hookData
        );

        emit AddJITLiquidity(
            poolKey.toId(),
            recipient,
            tickLower,
            tickUpper,
            addLiquidityDelta
        );
    }


   function removeJITLiquidity(
        bytes32 jitPositionKey,

        bytes calldata hookData
    ) external{
        uint256 jitTokenId = uint256(jitPositionKey);
        (PoolKey memory poolKey ,PositionInfo jitPositionInfo) = lpm.getPoolAndPositionInfo(jitTokenId);
        burnWhenUnlocked(
            jitTokenId,
            PositionConfig({
                poolKey: poolKey,
                tickLower: jitPositionInfo.tickLower(),
                tickUpper: jitPositionInfo.tickUpper()
            }),
            hookData
        );       
    }

    function mintWhenUnlocked(
        PositionConfig memory config, 
        uint256 liquidity, 
        address recipient, 
        bytes memory hookData
    ) internal {
        Plan memory plan = Planner.init();
        plan.add(
            Actions.MINT_POSITION,
            abi.encode(
                config.poolKey,
                config.tickLower,
                config.tickUpper,
                liquidity,
                MAX_SLIPPAGE_INCREASE,
                MAX_SLIPPAGE_INCREASE,
                recipient,
                hookData
            )
        );
        plan.add(Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency0));
        plan.add(Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency1));

        lpm.modifyLiquiditiesWithoutUnlock(
            plan.actions,
            plan.params
        );
    }

    
    
    function burnWhenUnlocked(
        uint256 tokenId,
        PositionConfig memory config,
        bytes memory hookData
    ) internal {
        Plan memory plan = Planner.init();
        plan.add(
            Actions.BURN_POSITION,
            abi.encode(
                tokenId,
                MIN_SLIPPAGE_DECREASE,
                MAX_SLIPPAGE_INCREASE,
                hookData
            )
        );
        plan.add(Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency0));
        plan.add(Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency1));

        lpm.modifyLiquiditiesWithoutUnlock(
            plan.actions,
            plan.params
        );
    }





}




