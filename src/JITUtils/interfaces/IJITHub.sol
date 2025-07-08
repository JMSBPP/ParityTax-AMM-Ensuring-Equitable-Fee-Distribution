// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IToxicityLevelCalculator} from "./IToxicityLevelCalculator.sol";

//NOTE:
// - JITHUbs set ToxicityLevelCalculator to determine their
//  perceived toxicity level
//

interface IJITHub {
    function getToxicityLevelCalculator()
        external
        view
        returns (IToxicityLevelCalculator);

    function setToxicityLevelCalculator(
        IToxicityLevelCalculator _toxicityLevelCalculator
    ) external;
}
