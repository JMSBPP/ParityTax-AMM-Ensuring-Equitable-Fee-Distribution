// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/test/shared/PosmTestSetup.sol";
import "../../src/routers/LiquidityTimeCommitmentRouter.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
contract LiquidityTimeCommitmentRouterTestSetup is PosmTestSetup {
    LiquidityTimeCommitmentRouter internal _liquidityTimeCommitmentRouter;

    function _deployLiquidityTimeCommitmentRouter() internal {
        deployFreshManager();
        _liquidityTimeCommitmentRouter = new LiquidityTimeCommitmentRouter(
            manager
        );

        manager.setProtocolFeeController(feeController);
    }
    function _deployMintAndApproveToLiquidityTimeCommitmentRouterCurrency()
        internal
        returns (Currency currency)
    {
        MockERC20 token = deployTokens(1, 2 * 255)[0];
        token.approve(
            address(_liquidityTimeCommitmentRouter),
            Constants.MAX_UINT256
        );

        return Currency.wrap(address(token));
    }

    function _deployMintAndApproveToLiquiditTimeCommitmentRouter2Currencies()
        internal
        returns (Currency currency0, Currency currency1)
    {
        Currency _currencyA = _deployMintAndApproveToLiquidityTimeCommitmentRouterCurrency();
        Currency _currencyB = _deployMintAndApproveToLiquidityTimeCommitmentRouterCurrency();
        (currency0, currency1) = SortTokens.sort(
            MockERC20(Currency.unwrap(_currencyA)),
            MockERC20(Currency.unwrap(_currencyB))
        );
    }
}
