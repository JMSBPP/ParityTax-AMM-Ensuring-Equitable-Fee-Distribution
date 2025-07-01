// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "./TimeCommitmentTest.sol";

contract TestTimeCommitment is Test {
    //NOTE: let's do fork testing from here on Unichain testnet

    TimeCommitmentLibrary private timeCommitmentLibrary;
    function setUp() public {
        vm.roll(21_100_900);
        timeCommitmentLibrary = new TimeCommitmentLibrary();
    }

    function test__fuzz__toTimeCommitment(
        uint48 _timeCommitmentValue
    ) public view {
        uint48 currentBlockTimestamp = uint48(vm.getBlockTimestamp());
        TimeCommitment timeCommitment = toTimeCommitment(_timeCommitmentValue);
        assertEq(timeStamp(timeCommitment), currentBlockTimestamp);
    }

    function test__fuzz__addTimeCommitments(
        TimeCommitment t1,
        TimeCommitment t2
    ) public {
        vm.startPrank(makeAddr("Alice"));
        // If there  t1 (an lp is a PLP) and wants to modify
        // the position to JIT, this shoudl revert
        TimeCommitment t1Plust2;
        vm.assume(t1 < t2);
        if (PLP(t1) && timeCommitmentValue(t2) == JIT_FLAG) {
            vm.expectRevert();
            timeCommitmentLibrary.Add(t1, t2);

            // Conversely if a JIT wants to now be a PLP, this should be possibe
        } else if (timeCommitmentValue(t1) == JIT_FLAG && PLP(t2)) {
            t1Plust2 = timeCommitmentLibrary.Add(t1, t2);
            assertEq(PLP(t1Plust2), true);
            assertEq(
                TimeCommitment.unwrap(t1Plust2),
                TimeCommitment.unwrap(t2)
            );
            //NOTE: Having to PLP commitments, results on the
            // addition of the timeCommitmentValues
        } else if (PLP(t1) && PLP(t2)) {
            t1Plust2 = timeCommitmentLibrary.Add(t1, t2);
            assertEq(PLP(t1Plust2), true);
            assertEq(
                timeCommitmentValue(t1Plust2),
                timeCommitmentValue(t1) + timeCommitmentValue(t2)
            );
            assertEq(vm.getBlockTimestamp(), timeStamp(t1Plust2));
            //NOTE: Adding a JIT commitment to a JIT commitment is a JIT
        }
        vm.stopPrank();
    }
}
