//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractFromBridge.sol";

/**
 * @title DynamicFromBridge
 * @dev For the moment, this contract is the exact concrete version AbstractFromBridge.
 */
contract DynamicFromBridge is AbstractFromBridge {
    /**
     * @dev Constructor
     */
    constructor(address validator_) AbstractFromBridge(validator_) {}
}
