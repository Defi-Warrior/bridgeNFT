//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractDynamicFromBridge.sol";
import "./AbstractBurningFromBridge.sol";
import "./AbstractRevocableFromBridge.sol";

/**
 * @title DynamicBurningRevocableFromBridge
 * @dev The version of FromBridge that is "dynamic", "burning" and "revocable".
 * See respective parent contracts for further explanations.
 */
contract DynamicBurningRevocableFromBridge is AbstractDynamicFromBridge, AbstractBurningFromBridge, AbstractRevocableFromBridge {
    /**
     * @dev Constructor.
     */
    constructor(address validator) AbstractFromBridge(validator) {}

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
