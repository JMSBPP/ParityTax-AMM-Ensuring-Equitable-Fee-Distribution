// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/LPTimeCommmitmentSetUp.sol";
import "./types/LPTypeCommitmentTest.t.sol";
import "../src/LiquidityOperatorsRegistry.sol";
import "../src/routers/LPTypeLiquidityRouter.sol";

contract LiquidityOperatorsRegistryTest is Test, LPTypeCommitmentTest {
    LiquidityOperatorsRegistry liquidityOperatorsRegistry;
    LPTypeLiquidityRouter router;
    function setUp() public virtual override {
        super.setUp();

        // We need to make sure that the router is the one
        // deploying the liquidity operators registry
        router = new LPTypeLiquidityRouter(IPoolManager(manager));
        vm.startPrank(address(router));
        liquidityOperatorsRegistry = new LiquidityOperatorsRegistry();
        vm.stopPrank();
        // NOTE: We are assumming here this contract has the permissions
        // to set the liquidity operators registry
        vm.startPrank(address(this));

        router.setLiquidityOperatorsRegistryAddress(
            address(liquidityOperatorsRegistry)
        );

        vm.stopPrank();
    }

    function test__Unit__RouterMustOwnLiquidityOperatorsRegistry()
        external
        view
    {
        assertEq(liquidityOperatorsRegistry.owner(), address(router));
    }

    function test__Fuzz__setLPTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        uint256 blockNumber,
        bool isJIT
    ) public returns (LPTimeCommitment memory resultLpTimeCommitment) {
        //NOTE: In practic there is access control over the addresses that
        // can call this function
        // In this case the pool is initiated by address(this)
        (Currency currency0, Currency currency1) = deployAndMint2Currencies();
        //NOTE: The parameters of the Pool are irrelevant as we are not testing any
        // pool behavior in this test ...
        (PoolKey memory irrelevantKey, ) = initPool(
            currency0,
            currency1,
            IHooks(address(0)),
            3000,
            SQRT_PRICE_1_1
        );
        vm.assume(
            (startingBlock <= endingBlock) &&
                (startingBlock > blockNumber) &&
                (blockNumber > 0)
        );
        vm.roll(blockNumber);
        assertEq(block.number, blockNumber);

        LPTimeCommitment memory liquidityTypeTimeCommitment = LPTimeCommitment({
            liquidityOperator: ILiquidityOperator(
                isJIT ? address(jitHook) : address(plpOperator)
            ),
            lpType: isJIT ? LPType.JIT : LPType.PLP,
            startingBlock: startingBlock,
            endingBlock: isJIT ? startingBlock : endingBlock
        });
        console.log(
            "LP Type:",
            uint256(uint8(liquidityTypeTimeCommitment.lpType))
        );
        console.log("starting Block:", startingBlock);
        console.log("Current Block:", block.number);
        console.log("ending Block:", endingBlock);
        console.log(
            "Liquidity Provider Address:",
            isJIT ? address(jitHook) : address(plpOperator)
        );

        vm.startPrank(isJIT ? jit : plp);
        router.modifyLiquidity(
            irrelevantKey,
            LIQUIDITY_PARAMS,
            abi.encode(liquidityTypeTimeCommitment)
        );

        vm.stopPrank();

        //NOTE: At this point the timeCommitment has been stored
        // on the LiquidityOperatorsRegistry
        // The get function can be called by anyone
        // this is to be reviewed
        vm.startPrank(address(this));
        resultLpTimeCommitment = liquidityOperatorsRegistry.getLPTimeCommitment(
            isJIT ? jit : plp
        );
        assertEq(
            address(resultLpTimeCommitment.liquidityOperator),
            isJIT ? address(jitHook) : address(plpOperator)
        );
        assertEq(
            uint8(resultLpTimeCommitment.lpType),
            uint8(isJIT ? LPType.JIT : LPType.PLP)
        );
        assertEq(resultLpTimeCommitment.startingBlock, startingBlock);
        assertEq(
            resultLpTimeCommitment.endingBlock,
            isJIT ? startingBlock : endingBlock
        );
        vm.stopPrank();
    }
}
