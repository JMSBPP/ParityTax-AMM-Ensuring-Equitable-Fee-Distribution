//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../../src/base/JITResolverBase.sol";

import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; 

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import {PoolKey,PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {LiquidityMath} from "@uniswap/v4-core/src/libraries/LiquidityMath.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";



import {IERC20} from "forge-std/interfaces/IERC20.sol";


import {
    LiquidityOperations,
    Planner,
    Plan,
    PositionConfig,
    LiquidityAmounts,
    Actions
} from "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {console2} from "forge-std/Test.sol";
import {PositionManager} from "@uniswap/v4-periphery/src/PositionManager.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

contract MockJITResolver is JITResolverBase, LiquidityOperations, ImmutableState{
    using SafeCast for *;
    using CurrencySettler for Currency;
    using StateLibrary for IPoolManager;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;    
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using Address for address;
    using Position for address;


    // NOTE: The JIT Operators are identified by their positionKey

    IAllowanceTransfer permit2;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;



    //NOTE: This is a placeHolder for testing
    address jitResolver;
    mapping(PoolId poolId => bytes32 positionKey) private jitOperators;


    constructor(
        IPoolManager _manager,
        IPositionManager _lpm,
        IAllowanceTransfer _permit2
    ) ImmutableState (_manager) {
        lpm = _lpm;
        permit2 = _permit2;
    }



    function addLiquidity(JITData memory jitData) external returns(uint256, PositionConfig memory){
        //NOTE: This is  place holder, further checks are needed
        
        uint256 amountToFullfill = jitData.amountOut;

        // NOTE : At this point the JITHub has a debit of the amount of liquidity he will provide
        // to the swap
        uint256 jitLiquidity = uint256(
            jitData.beforeSwapSqrtPriceX96.getLiquidityForAmount1(
                jitData.expectedAfterSwapSqrtPriceX96,
                amountToFullfill
            )
        );

        //NOTE: This is provisional, because the JITData needs to give the PoolKey not
        // the PoolId
        (, int24 currentTick,,) = poolManager.getSlot0(jitData.poolKey.toId());
        
        PositionConfig memory jitPosition = PositionConfig({
            poolKey: jitData.poolKey,
            tickLower: currentTick,
            tickUpper: jitData.expectedAfterSwapTick
        });
        _mintUnlocked(
            jitPosition,
            jitLiquidity,
            address(this),
            Constants.ZERO_BYTES
        );
        uint256 _tokenId = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "nextTokenId()"
                )
            ),
            (uint256)
        );

        bytes32 jitPositionKey = address(this).calculatePositionKey(
            jitPosition.tickLower,
            jitPosition.tickUpper,
            bytes32(_tokenId)
        );
        (PoolKey memory _poolKey, PositionInfo jitPositionInfo ) = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "getPoolAndPositionInfo(uint256)", _tokenId
                )
            ),
            (PoolKey, PositionInfo)
        );

        console2.log(
            "JIT Position Info",
            PositionInfo.unwrap(jitPositionInfo)
        );



        // NOTE: After minting the position our position is the latest tokenId
        // minted, therefore is safe to call the nextTokenId() on the positionManager
        // to query our positionTokenId
        return (jitLiquidity, jitPosition);
    }

    function removeLiquidity(uint256 tokenId) external{
     

        PositionInfo jitPositionInfo = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "positionInfo(uint256)",
                    (tokenId)
                )
            )
            ,
            (PositionInfo)
        );

        PoolKey memory poolKey = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "poolKeys(bytes25)", 
                    (jitPositionInfo.poolId()))
            ),
            (PoolKey)
        );

        PositionConfig memory jitPositionConfig = PositionConfig({
            poolKey: poolKey,
            tickLower: jitPositionInfo.tickLower(),
            tickUpper: jitPositionInfo.tickUpper()
        });

        _burnUnlocked(
            tokenId,
            jitPositionConfig
        );


    }

    function _mintUnlocked(
        PositionConfig memory config,
        uint256 liquidity,
        address recipient,
        bytes memory hookData
    ) internal {
        Plan memory planner = Planner.init();
        {
            planner.add(
                Actions.MINT_POSITION,
                abi.encode(
                    config.poolKey,
                    config.tickLower < config.tickUpper ?config.tickLower:config.tickUpper,
                    config.tickLower < config.tickUpper ?config.tickUpper:config.tickLower,
                    liquidity,
                    MAX_SLIPPAGE_INCREASE,
                    MAX_SLIPPAGE_INCREASE,
                    recipient,
                    hookData
                )
            );
            planner.add(
                Actions.CLOSE_CURRENCY,
                abi.encode(config.poolKey.currency0)
            );
            planner.add(
                Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency1)
            );
        }
        
        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }

    function _burnUnlocked(
        uint256 tokenId,
        PositionConfig memory config
    ) internal {
        Plan memory planner = Planner.init();
        planner.add(
            Actions.BURN_POSITION,
            abi.encode(
                tokenId,
                MIN_SLIPPAGE_DECREASE,
                MIN_SLIPPAGE_DECREASE,
                Constants.ZERO_BYTES
            )
        );

        planner.add(
            Actions.CLOSE_CURRENCY,
            abi.encode(config.poolKey.currency0)
        );
        planner.add(
            Actions.CLOSE_CURRENCY, 
            abi.encode(config.poolKey.currency1)
        );

        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    } 




    function whiteListResolver(
        address _resolver
    ) internal {
        jitResolver = _resolver;
    }

   

    function _queryJITAmounts(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory jitLiquidityParams
    ) internal view returns(uint256 liquidity0, uint256 liquidity1, uint128 newLiquidity){
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,int24 tick,,) = poolManager.getSlot0(poolId);
        (int24 tickLower, int24 tickUpper) = (
            jitLiquidityParams.tickLower,
            jitLiquidityParams.tickUpper
        );
        uint128 liquidity = poolManager.getLiquidity(poolId);
        int256 liquidityDelta = jitLiquidityParams.liquidityDelta;
        BalanceDelta delta;
        if (tick < tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ currency0 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount0Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper),
                        liquidityDelta.toInt128().toUint128(),
                        false
                    ).toInt128(),
                    int128(0x00)
                );
            } else if (tick < tickUpper) {
                delta = toBalanceDelta(
                    sqrtPriceX96.getAmount0Delta(TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false)
                        .toInt128(),
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(sqrtPriceX96, liquidityDelta.toInt128().toUint128(), false)
                        .toInt128()
                );

                newLiquidity = LiquidityMath.addDelta(liquidity, liquidityDelta.toInt128());
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ currency1 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    0,
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false
                    ).toInt128()
                );
            }

            (liquidity0, liquidity1) = (
                delta.amount0() < 0 ? uint256(uint128(-delta.amount0())) : uint256(delta.amount0().toUint128()),
                delta.amount1() < 0 ? uint256(uint128(-delta.amount1())) : uint256(delta.amount1().toUint128())
            );

        }
}