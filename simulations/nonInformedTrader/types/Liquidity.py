class Token:

    def __init__(self, supply):
        self.supply = supply
    def getSupply(self):
        return self.supply

class Liquidity:
    def __init__(self, liquidity0, liquidity1):
        self.token0 = Token(liquidity0)
        self.token1 = Token(liquidity1)
        self.reserve0 = liquidity0
        self.reserve1 = liquidity1

    def setLiquidity(self):
        self.liquidity = self.reserve0*self.reserve1
 
