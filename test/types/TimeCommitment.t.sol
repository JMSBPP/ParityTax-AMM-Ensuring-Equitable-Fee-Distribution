// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "./TimeCommitmentTest.sol";

uint48 constant DEFAULT_BLOCK_TIMESTAMP = uint48(21_100_900);

contract TestTimeCommitment is Test {
    //NOTE: let's do fork testing from here on Unichain testnet

    TimeCommitmentLibraryTest private timeCommitmentLibrary;
    mapping(bytes32 positionKey => TimeCommitment) testPositionKeysTimeCommitments;
    
    function setUp() public {
        vm.warp(DEFAULT_BLOCK_TIMESTAMP);
        timeCommitmentLibrary = new TimeCommitmentLibraryTest();
    }

    function test__fuzz__toTimeCommitment(
        uint48 _timeCommitmentValue
    ) public view {
        uint48 currentBlockTimestamp = uint48(vm.getBlockTimestamp());

        TimeCommitment timeCommitment = toTimeCommitment(_timeCommitmentValue);
        assertEq(timeStamp(timeCommitment), currentBlockTimestamp);
    }

    function test__fuzz__PLP(uint48 _plpTimeCommitmentValue) external{
        //NOTE: We set a PLP timeCommitment
        uint48 plpTimeCommitmentValue = uint48(bound(_plpTimeCommitmentValue, vm.getBlockTimestamp(), type(uint48).max-1));
        TimeCommitment plpTimeCommitment = toTimeCommitment(plpTimeCommitmentValue);
        assertTrue(PLP(plpTimeCommitment)); 
    }


    function test__fuzz__Uninitialized(bytes32 _randomBytes32) external{
        //NOTE: The default value of empty TimeCommitments should be
        // uninitialized
        bytes32 randomBytes32 = bytes32(bound(uint256(_randomBytes32), 0, type(uint256).max));
        TimeCommitment emptyTimeCommitment = testPositionKeysTimeCommitments[randomBytes32];
        assertTrue(UNINITIALIZED(emptyTimeCommitment));
        console.logBytes(abi.encode(timeCommitmentLibrary.set(emptyTimeCommitment)));
    }

    function test__fuzz__timeStamp(uint48 _timeCommitmentValue) external{
        TimeCommitment randomTimeCommitment = toTimeCommitment(_timeCommitmentValue);
        assertEq(uint256(vm.getBlockTimestamp()), uint256(timeStamp(randomTimeCommitment)));
    }

    //NOTE: Equality is not tested as it is not a reachable state because two timeCommitments can not be
    // entered async because the EVM is sequential.

    function test__fuzz__ltGt(uint48 randomBlockTimeStampX1, uint48 randomBlockTimeStampX2 ,uint48 timeCommitmentValueX1, uint48 timeCommitmentValueX2) external{
        //NOTE: UNINITIALIZED TC is the lowest bound
        vm.warp(randomBlockTimeStampX1);
        uint48 timeStampX1 = uint48(vm.getBlockTimestamp()); 
        TimeCommitment timeCommitmentX1 = timeCommitmentLibrary.set(toTimeCommitment(timeCommitmentValueX1));
        console.log("First Time Commitment:",timeStamp(timeCommitmentX1));
        {
            vm.warp(uint256(randomBlockTimeStampX2));
            uint48 timeStampX2 = uint48(vm.getBlockTimestamp());
            TimeCommitment timeCommitmentX2 = timeCommitmentLibrary.set(toTimeCommitment(timeCommitmentValueX2));
            if (timeStampX2 > timeStampX1){
                assertTrue(timeCommitmentX2 > timeCommitmentX1);
            }else if (timeStampX2 < timeStampX1){
                assertTrue(timeCommitmentX2 < timeCommitmentX1);
            }       
        }    
    }

    function test__fuzz__addTimeCommitments(bytes32 randomKey,uint48 blockTimeStampX1,uint48 blockTimeStampX2,uint48 __timeCommitmentValueX1, uint48 __timeCommitmentValueX2) external{
        //NOTE let's set the case when the lp initiates the
        // position for the fisrt time. This is
        vm.assume( (blockTimeStampX1 > DEFAULT_BLOCK_TIMESTAMP) && (blockTimeStampX1 < blockTimeStampX2));
        uint48 _timeCommitmentValueX1 = uint48(bound(__timeCommitmentValueX1, 0, type(uint48).max));
        //NOTE The current block.timeStamp needs to be the Default one
        assertEq(uint256(DEFAULT_BLOCK_TIMESTAMP),vm.getBlockTimestamp());
        // NOTE: Then if the LP has not set any timeCommitments before we have:
        TimeCommitment emptyTimeCommitment = testPositionKeysTimeCommitments[randomKey];
        //NOTE: This timeCommitment has a block.timeStamp of 0
        assertTrue(UNINITIALIZED(emptyTimeCommitment));
        vm.warp(uint256(blockTimeStampX1));
        TimeCommitment timeCommitmentX1 = toTimeCommitment(_timeCommitmentValueX1);
        {
            console.log("Time Commmitment TimeStamp:",timeStamp(timeCommitmentX1));
            console.log("Time Commitment Value:", timeCommitmentValue(timeCommitmentX1));
        }
        // NOTE: This is the case where we have an Unitialized position and we are free
        // to set it as we want as long as it si JIT or PLP
        vm.startPrank(address(this));
        TimeCommitment t1Plust2 = timeCommitmentLibrary.Add(emptyTimeCommitment, timeCommitmentX1);
        if (UNINITIALIZED(timeCommitmentX1)){
            // This is equiavlent to having specified an empty position to an already emptyPosition
            // this returns an empty position
            assertEq(TimeCommitment.unwrap(t1Plust2),TimeCommitment.unwrap(emptyTimeCommitment));
        }else{
            // The other case is initiating a non empty position
            assertEq(TimeCommitment.unwrap(t1Plust2), TimeCommitment.unwrap(timeCommitmentX1));
        }
        testPositionKeysTimeCommitments[randomKey] = t1Plust2;
        vm.stopPrank();
        
        uint48 _timeCommitmentValueX2 = uint48(bound(__timeCommitmentValueX2,1, type(uint48).max));
        
        

    }
}
