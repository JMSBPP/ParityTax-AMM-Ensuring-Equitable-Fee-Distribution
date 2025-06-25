// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../utils/TimeCommitmentTest.sol";

contract TimeCommitmentTest is Test {
    TimeCommitmentLibraryTest timeCommitmentLibrary;

    function setUp() public {
        timeCommitmentLibrary = new TimeCommitmentLibraryTest();
    }

}
