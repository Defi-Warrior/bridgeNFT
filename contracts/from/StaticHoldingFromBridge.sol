//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractStaticFromBridge.sol";
import "./AbstractHoldingFromBridge.sol";

/**
 * @title StaticHoldingFromBridge
 * @dev 
 */
contract StaticHoldingFromBridge is AbstractStaticFromBridge, AbstractHoldingFromBridge {
    /**
     * @dev Constructor
     */
    constructor(address validator_, address fromToken) AbstractFromBridge(validator_) AbstractStaticFromBridge(fromToken) {}

    /**
     * @dev See AbstractStaticFromBridge.
     * @return result of "super.getTokenUri" function.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual
            override(AbstractFromBridge, AbstractStaticFromBridge) returns (bytes memory) {
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
    ) public virtual override(AbstractFromBridge, AbstractStaticFromBridge) {
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
