//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FiscalState
 * @author ParityTax Team
 * @notice Proxy contract for fiscal policy state management in the ParityTax system
 * @dev This contract serves as an upgradeable proxy for fiscal policy implementations,
 * allowing for seamless upgrades of fiscal logic while maintaining state continuity.
 * @dev Inherits from OpenZeppelin's ERC1967Proxy for standard proxy functionality
 * and upgrade mechanisms. Critical for maintaining fiscal policy state across
 * system upgrades and ensuring consistent taxation calculations.
 */

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @notice Upgradeable proxy contract for fiscal policy state management
 * @dev Extends ERC1967Proxy to provide upgradeable fiscal policy functionality
 * @dev The implementation contract contains the actual fiscal policy logic,
 * while this proxy maintains the state and delegates calls to the implementation
 */
contract FiscalState is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) payable {}
}