
from types.Liquidity import Liquidity
# How do we go about defining the price class:
## This s going to be inherited by AMM internal price
## And external market price:
class Price:
    def __init__(self, liquidity0, liquidity1, initialValue):
        self.liquiditySupply = Liquidity(liquidity0, liquidity1)
        self.initialValue = liquidity0/liquidity1
        self.currentValue = initialValue
    def resposnseToBuyOrder(self):