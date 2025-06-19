// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// {
//     (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
//         getFeeGrowthInside(self, tickLower, tickUpper);

//     Position.State storage position = self.positions.get(params.owner, tickLower, tickUpper, params.salt);
//     (uint256 feesOwed0, uint256 feesOwed1) =
//         position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

//     // Fees earned from LPing are calculated, and returned
//     feeDelta = toBalanceDelta(feesOwed0.toInt128(), feesOwed1.toInt128());
// }
// function update(
//     State storage self,
//     int128 liquidityDelta,
//     uint256 feeGrowthInside0X128,
//     uint256 feeGrowthInside1X128
// ) internal returns (uint256 feesOwed0, uint256 feesOwed1) {
//     uint128 liquidity = self.liquidity;

//     if (liquidityDelta == 0) {
//         // disallow pokes for 0 liquidity positions
//         if (liquidity == 0) CannotUpdateEmptyPosition.selector.revertWith();
//     } else {
//         self.liquidity = LiquidityMath.addDelta(liquidity, liquidityDelta);
//     }

//     // calculate accumulated fees. overflow in the subtraction of fee growth is expected
//     unchecked {
//         feesOwed0 =
//             FullMath.mulDiv(feeGrowthInside0X128 - self.feeGrowthInside0LastX128, liquidity, FixedPoint128.Q128);
//         feesOwed1 =
//             FullMath.mulDiv(feeGrowthInside1X128 - self.feeGrowthInside1LastX128, liquidity, FixedPoint128.Q128);
//     }

//     // update the position
//     self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
//     self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
