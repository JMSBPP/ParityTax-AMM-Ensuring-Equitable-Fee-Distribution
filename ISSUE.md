# Custom Liquidity Router Issue

I have a custom liquidity router for liquidity operations in `test/mocks/MockJITResolver.sol` that mints liquidity in the `beforeSwap` function of `src/ParittTaxHook.sol`.

It mints a position as shown below:

```solidity
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
                    config.tickLower < config.tickUpper ? config.tickLower : config.tickUpper,
                    config.tickLower < config.tickUpper ? config.tickUpper : config.tickLower,
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
```

However, I am trying to retrieve the `tokenId` of this position in order to burn the position in `afterSwap`.

As far as I understand, it should be enough to call `nextTokenId` on the `positionManager`, since `tokenId` is guaranteed to remain invariant when called within the same transaction. But when running:

```sh
forge test --mt test__Unit_JITSingleLP -vvvv
```

It shows that there is no position nor pool associated with such token:

```solidity
    function addLiquidity(JITData memory jitData) external returns(uint256, PositionConfig memory) {
        // NOTE: This is a placeholder, further checks are needed
        
        uint256 amountToFulfill = jitData.amountOut;

        // NOTE: At this point the JITHub has a debit of the amount of liquidity it will provide
        // to the swap
        uint256 jitLiquidity = uint256(
            jitData.beforeSwapSqrtPriceX96.getLiquidityForAmount1(
                jitData.expectedAfterSwapSqrtPriceX96,
                amountToFulfill
            )
        );

        // NOTE: This is provisional, because the JITData needs to provide the PoolKey
        // instead of the PoolId
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
        (PoolKey memory _poolKey, PositionInfo jitPositionInfo) = abi.decode(
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

        // NOTE: After minting the position, our position is the latest tokenId
        // minted. Therefore, it is safe to call nextTokenId() on the positionManager
        // to query our positionTokenId.
        return (jitLiquidity, jitPosition);
    }
```

I just want to burn the position — I bet there is a simpler approach.
Any help will be highly appreciated.

https://github.com/JMSBPP/ParityTax-AMM-Ensuring-Equitable-Fee-Distribution
