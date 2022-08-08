//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractDynamicFromBridge.sol";
import "./AbstractHoldingFromBridge.sol";
import "./AbstractRevocableFromBridge.sol";

/**
 * @title DynamicHoldingRevocableFromBridge
 * @dev The version of FromBridge that is "dynamic", "holding" and "revocable".
 * See respective parent contracts for further explanations.
 */
contract DynamicHoldingRevocableFromBridge is AbstractDynamicFromBridge, AbstractHoldingFromBridge, AbstractRevocableFromBridge {
    /**
     * @dev Constructor.
     */
    constructor(address validator) AbstractFromBridge(validator) {}

    /* ********************************************************************************************** */

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

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractRevocableFromBridge.
     */
    function getValidatorSignature(uint256 requestNonce) public view virtual
            override(AbstractFromBridge, AbstractRevocableFromBridge) returns(bytes memory) {
        // Will call "AbstractRevocableFromBridge.getValidatorSignature" function.
        return super.getValidatorSignature(requestNonce);
    }
}
