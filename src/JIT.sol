// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IStateView} from "@uniswap/v4-periphery/src/interfaces/IStateView.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// This contract aims to be a calculator of JIT operations
import {Pool} from "@uniswap/v4-core/src/libraries/Pool.sol";
import {PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Slot0, Slot0Library} from "@uniswap/v4-core/src/types/Slot0.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
contract JIT is Initializable {
    using PoolIdLibrary for PoolKey;
    using Slot0Library for Slot0;
    using Address for address;
    using BalanceDeltaLibrary for BalanceDelta;
    /// @custom:storage-location erc7201:openzeppelin.storage.JIT    
    struct JITStorage{
        IPoolManager _poolManager;
        IStateView _stateView;
        PoolKey _poolKey;
    }
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.JIT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant JITStorageLocation = 0x2a45e999019fda730a9321cc467338cd05c558f189040d015df82e533397c600;

    function _getJITStorage() private pure returns (JITStorage storage $) {
        assembly {
            $.slot := JITStorageLocation
        }
    }

    function poolKey() public view returns(PoolKey memory __poolKey){
        JITStorage storage $ = _getJITStorage();
        __poolKey = $._poolKey;
    }

    function poolManager() public view returns(IPoolManager manager){
        JITStorage storage $ = _getJITStorage();
        manager = $._poolManager;
    }

    function stateView() public view returns(IStateView viewer){
        JITStorage storage $ = _getJITStorage();
        viewer = $._stateView;
    }

    function initialize(
        PoolKey calldata key,
        IPoolManager  manager,
        IStateView viewer
    ) public virtual initializer {
        JITStorage storage $ = _getJITStorage();
        $._poolManager = manager;
        $._poolKey = key;
        $._stateView = viewer;
    }


    event DeltaAmounts(int128 amount0, int128 amount1);
    /// @notice Defines the amount of tokens to be used in the JIT position
    /// @dev No tokens should be transferred into the PoolManager by this function. The afterSwap implementation, will handle token flows
    /// @param params the swap params passed in during swap
    /// @param data external call data to quote for custom curves
    /// @return amount0 the amount of currency0 to be used for JIT position
    /// @return amount1 the amount of currency1 to be used for JIT position
    function _jitAmounts(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes memory data
    ) internal virtual returns (int128, int128)
        {
            if (data.length >0){
               // NOTE: It allows the excecution of custom logic
                return (0, 0);

            } else {
                bytes memory encodedSwapDelta = address(poolManager()).functionStaticCall(
                    abi.encodeCall(IPoolManager.swap, (key, params, bytes("")))
                );
                BalanceDelta swapDelta = BalanceDelta.wrap(
                    abi.decode(
                        encodedSwapDelta,
                        (int256)
                    )
                );
                (int128 traderAmount0, int128 traderAmount1) = (
                    swapDelta.amount0(),
                    swapDelta.amount1()
                );

                emit DeltaAmounts(traderAmount0, traderAmount1);
                return (traderAmount0, traderAmount1);
                 
            }
                
        }

}
