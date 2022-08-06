//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./interfaces/IBurningFromBridge.sol";
import "./AbstractFromBridge.sol";

/**
 * @title AbstractBurningFromBridge
 * @dev The version of FromBridge that burns the requested tokens.
 */
abstract contract AbstractBurningFromBridge is IBurningFromBridge, AbstractFromBridge {
    /**
     * @dev See AbstractFromBridge.
     * Process the token by burning it.
     */
    function _processToken(
        Origin memory origin,
        address tokenOwner,
        uint256 tokenId
    ) internal virtual override {
        ERC721Burnable(origin.fromToken).burn(tokenId);
    }

    /**
     * @dev See AbstractFromBridge.
     * Emit "BurnedTokenUri" event to store token URI.
     */
    function _emitEvents(
        Origin memory origin,
        Destination calldata destination,
        RequestId calldata requestId,
        TokenInfo memory tokenInfo,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual override {
        // Will call "AbstractFromBridge._emitEvents" function.
        super._emitEvents(
            origin,
            destination,
            requestId,
            tokenInfo,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);

        emit BurnedTokenUri(
            origin.fromToken,
            requestId.tokenOwner,
            requestId.requestNonce,
            tokenInfo.tokenId,
            tokenInfo.tokenUri);
    }
}
