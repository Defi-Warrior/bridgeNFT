//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractStaticFromBridge.sol";
import "./AbstractBurningFromBridge.sol";
import "./AbstractRevocableFromBridge.sol";

/**
 * @title StaticBurningRevocableFromBridge
 * @dev The version of FromBridge that is "static", "burning" and "revocable".
 * See respective parent contracts for further explanations.
 */
contract StaticBurningRevocableFromBridge is AbstractStaticFromBridge, AbstractBurningFromBridge, AbstractRevocableFromBridge {
    /**
     * @dev Constructor.
     */
    constructor(address validator, address fromToken) AbstractFromBridge(validator) AbstractStaticFromBridge(fromToken) {}

    /**
     * @dev See AbstractStaticFromBridge.
     * @return result of "super.getTokenUri" function.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual
            override(IFromBridge, AbstractFromBridge, AbstractStaticFromBridge) returns(bytes memory) {
        // Will call "AbstractStaticFromBridge.getTokenUri" function.
        return super.getTokenUri(fromToken, tokenId);
    }

    /**
     * @dev See AbstractStaticFromBridge.
     */
    function commit(
        address fromToken,
        Destination calldata destination,
        RequestId calldata requestId,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) public virtual override(IFromBridge, AbstractFromBridge, AbstractStaticFromBridge) {
        // Will call "AbstractStaticFromBridge.commit" function.
        super.commit(
            fromToken,
            destination,
            requestId,
            tokenId,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature
        );
    }

    /**
     * @dev See AbstractBurningFromBridge.
     */
    function _processToken(
        Origin memory origin,
        address tokenOwner,
        uint256 tokenId
    ) internal override(AbstractFromBridge, AbstractBurningFromBridge) {
        // Will call "AbstractBurningFromBridge._processToken" function.
        super._processToken(origin, tokenOwner, tokenId);
    }

    /**
     * @dev See AbstractBurningFromBridge.
     */
    function _emitEventsWhenCommit(
        Origin memory origin,
        Destination calldata destination,
        RequestId calldata requestId,
        TokenInfo memory tokenInfo,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual override(AbstractFromBridge, AbstractBurningFromBridge) {
        // Will call "AbstractBurningFromBridge._emitEventsWhenCommit" function.
        super._emitEventsWhenCommit(
            origin,
            destination,
            requestId,
            tokenInfo,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);
    }

    /**
     * @dev See AbstractRevocableFromBridge.
     */
    function getValidatorSignature(uint256 requestNonce) public view virtual
            override(IFromBridge, AbstractFromBridge, AbstractRevocableFromBridge) returns(bytes memory) {
        // Will call "AbstractRevocableFromBridge.getValidatorSignature" function.
        return super.getValidatorSignature(requestNonce);
    }
}
