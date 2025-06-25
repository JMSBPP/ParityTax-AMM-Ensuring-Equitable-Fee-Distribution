// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "./LiquidityOperatorsRegistryTest.t.sol";
import "openzeppelin/utils/math/SafeMath.sol";

contract LPTypeLiquidityRouterTest is Test, LPTimeCommmitmentSetUp {
    using SafeMath for uint256;
    LiquidityOperatorsRegistry liquidityOperatorsRegistry;
    LPTypeLiquidityRouter router;

    function setUp() public override {
        super.setUp();
        //NOTE: We need a valid pool to get started
        //1 Deploy and mint the underlying
        // currencies
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
        (currency0, currency1) = deployAndMint2Currencies();
        // 2 Initialize the pool,
        // NOTE: We still do not care about
        // Hooks so let's put a hookless
        // pool ...
        // WARNING: This does not hold on
        // completed implementation
        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(address(liquidityTimeCommitmentHook)),
            3000,
            SQRT_PRICE_1_1
        );
        // NOTE: We need to supply the lp's
        // with some funds
        // let's split the supply in halfs for both curencies
        // to both lp's
        uint256 halfTokenSupply = uint256(type(uint160).max).div(2);
        {
            IERC20Minimal(Currency.unwrap(currency0)).transfer(
                jit,
                halfTokenSupply
            );
            IERC20Minimal(Currency.unwrap(currency1)).transfer(
                jit,
                halfTokenSupply
            );
            IERC20Minimal(Currency.unwrap(currency0)).transfer(
                plp,
                halfTokenSupply
            );
            IERC20Minimal(Currency.unwrap(currency1)).transfer(
                plp,
                halfTokenSupply
            );
        }

        //NOTE: Now we need to approve the router
        // to spend the lp's balances for both currencies
        {
            vm.startPrank(jit);
            IERC20Minimal(Currency.unwrap(currency0)).approve(
                address(router),
                halfTokenSupply
            );
            IERC20Minimal(Currency.unwrap(currency1)).approve(
                address(router),
                halfTokenSupply
            );
            vm.stopPrank();
        }
        {
            vm.startPrank(plp);
            IERC20Minimal(Currency.unwrap(currency0)).approve(
                address(router),
                halfTokenSupply
            );
            IERC20Minimal(Currency.unwrap(currency1)).approve(
                address(router),
                halfTokenSupply
            );
            vm.stopPrank();
        }
    }

    function test__Unit__MustAddLiquidityClaimableByLiquidityOperator() public {
        vm.roll(21_000_000);
        console.log("Current Block:", block.number);
        LPTimeCommitment memory unitTestJitTimeCommitment = LPTimeCommitment({
            liquidityOperator: ILiquidityOperator(address(jitHook)),
            lpType: LPType.JIT,
            startingBlock: block.number,
            endingBlock: block.number
        });
        LPTimeCommitment memory unitTestPlpTimeCommitment = LPTimeCommitment({
            liquidityOperator: ILiquidityOperator(address(plpOperator)),
            lpType: LPType.PLP,
            startingBlock: block.number,
            endingBlock: block.number + 1
        });
        vm.startPrank(plp);
        router.modifyLiquidity(
            key,
            LIQUIDITY_PARAMS,
            abi.encode(unitTestPlpTimeCommitment)
        );

        vm.stopPrank();
    }
}
