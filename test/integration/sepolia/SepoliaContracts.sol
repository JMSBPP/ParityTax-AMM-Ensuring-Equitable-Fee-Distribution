// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";

import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";


    
IPositionManager constant SEPOLIA_POSITION_MANAGER = IPositionManager(
    address(
        0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4
    )
);


IV4Quoter constant SEPOLIA_V4_QUOTER = IV4Quoter(
    address(
        0x61B3f2011A92d183C7dbaDBdA940a7555Ccf9227
    )
);

IPoolManager constant SEPOLIA_POOL_MANAGER = IPoolManager(
    address(
        0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
    )
);
