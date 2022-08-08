//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBurningFromBridgeEvents {
    /**
     * @dev This event is used to store URI of burned tokens.
     */
    event BurnedTokenUri(
        address indexed fromToken,
        address indexed tokenOwner,
        uint256 indexed requestNonce,
        uint256         tokenId,
        bytes           tokenUri);
}
