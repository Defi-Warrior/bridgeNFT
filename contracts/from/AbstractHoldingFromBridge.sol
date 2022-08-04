//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractFromBridge.sol";

/**
 * @title AbstractHoldingFromBridge
 * @dev 
 */
abstract contract AbstractHoldingFromBridge is AbstractFromBridge {
    /**
     * @dev See AbstractFromBridge.
     * Process the token by transfering it to FromBridge.
     */
    function _processToken(
        Origin memory origin,
        address tokenOwner,
        uint256 tokenId
    ) internal virtual override {
        IERC721(origin.fromToken).transferFrom(tokenOwner, origin.fromBridge, tokenId);
    }
}
