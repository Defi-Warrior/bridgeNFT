//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractFromBridge.sol";

/**
 * @title AbstractHoldingFromBridge
 * @dev The version of FromBridge that holds the requested tokens.
 * There is no functionality that transfers tokens out. Child contracts MAY implement if desired.
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
