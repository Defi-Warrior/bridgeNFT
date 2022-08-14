//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./AbstractFromBridge.sol";

/**
 * @title AbstractHoldingFromBridge
 * @dev The version of FromBridge that holds the requested tokens.
 * There is no functionality that transfers tokens out. Child contracts MAY implement if desired.
 */
abstract contract AbstractHoldingFromBridge is AbstractFromBridge, IERC721Receiver {
    /**
     * @dev See AbstractFromBridge.
     * Process the token by transfering it to FromBridge.
     */
    function _processToken(
        Origin memory origin,
        address tokenOwner,
        uint256 tokenId
    ) internal virtual override {
        IERC721(origin.fromToken).safeTransferFrom(tokenOwner, origin.fromBridge, tokenId);
    }

    /**
     * @dev Implement IERC721Receiver.
     * Child contracts MAY override to add more logic if needed.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
