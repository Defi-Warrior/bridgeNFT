//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IStaticFromBridge.sol";
import "./AbstractFromBridge.sol";

/**
 * @title AbstractStaticFromBridge
 * @dev 
 */
abstract contract AbstractStaticFromBridge is IStaticFromBridge, AbstractFromBridge {
    /**
     * Address (Ethereum format) of the token this FromBridge serves.
     */
    address private immutable _fromToken;

    modifier validateFromToken(address fromToken, string memory errorMessage) {
        require(fromToken == _fromToken, errorMessage);
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(address fromToken) {
        _fromToken = fromToken;
    }

    /**
     * @dev "_fromToken" getter.
     */
    function getFromToken() public view override returns(address) {
        return _fromToken;
    }

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.getTokenUri" to add fromToken validation.
     * @return result of "super.getTokenUri" function.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual override(IFromBridge, AbstractFromBridge)
            validateFromToken(fromToken, "getTokenUri: Only the token supported by this FromBridge is allowed to be called on")
            returns (bytes memory) {
        return super.getTokenUri(fromToken, tokenId);
    }

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.commit" to add fromToken validation.
     */
    function commit(
        address fromToken,
        Destination calldata destination,
        RequestId calldata requestId,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) public virtual override(IFromBridge, AbstractFromBridge)
    validateFromToken(fromToken, "commit: Only the token supported by this FromBridge is allowed to be called on") {
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
}