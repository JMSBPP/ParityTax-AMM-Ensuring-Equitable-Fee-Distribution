// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/TimeCommitment.sol";

contract TimeCommitmentLibraryTest {
    using TimeCommitmentLibrary for TimeCommitment;
    function Add(
        TimeCommitment t1,
        TimeCommitment t2
    ) external returns (TimeCommitment t1Plust2) {
        t1Plust2 = add(t1, t2);
    }

    function set(TimeCommitment self) external view returns(TimeCommitment timeCommitment){
        timeCommitment = self.set();
    }
}
