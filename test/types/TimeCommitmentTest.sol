// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/TimeCommitment.sol";

contract TimeCommitmentLibrary {
    function Add(
        TimeCommitment t1,
        TimeCommitment t2
    ) external view returns (TimeCommitment t1Plust2) {
        t1Plust2 = add(t1, t2);
    }
}
