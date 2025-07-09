// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//TODO: This needs to be a dedicated type
type ToxicityLevel is uint8;
//NOTE: There is some bitMap job here to determine the toxicity level

using ToxicityLevelLibrary for ToxicityLevel global;

library ToxicityLevelLibrary {}
