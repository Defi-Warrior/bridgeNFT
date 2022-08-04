//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractDynamicFromBridge.sol";
import "./AbstractBurningFromBridge.sol";

/**
 * @title DynamicBurningFromBridge
 * @dev 
 */
contract DynamicBurningFromBridge is AbstractDynamicFromBridge, AbstractBurningFromBridge {
    /**
     * @dev Constructor
     */
    constructor(address validator_) AbstractFromBridge(validator_) {}

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
    function _emitEvents(
        Origin memory origin,
        Destination calldata destination,
        RequestId calldata requestId,
        TokenInfo memory tokenInfo,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual override(AbstractFromBridge, AbstractBurningFromBridge) {
        // Will call "AbstractBurningFromBridge._emitEvents" function.
        super._emitEvents(
            origin,
            destination,
            requestId,
            tokenInfo,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);
    }
}
