//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractDynamicFromBridge.sol";
import "./AbstractHoldingFromBridge.sol";

/**
 * @title DynamicHoldingFromBridge
 * @dev 
 */
contract DynamicHoldingFromBridge is AbstractDynamicFromBridge, AbstractHoldingFromBridge {
    /**
     * @dev Constructor
     */
    constructor(address validator_) AbstractFromBridge(validator_) {}

    /**
     * @dev See AbstractHoldingFromBridge.
     */
    function _processToken(
        Origin memory origin,
        address tokenOwner,
        uint256 tokenId
    ) internal override(AbstractFromBridge, AbstractHoldingFromBridge) {
        // Will call "AbstractHoldingFromBridge._processToken" function.
        super._processToken(origin, tokenOwner, tokenId);
    }
}
