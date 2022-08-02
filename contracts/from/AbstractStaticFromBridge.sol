//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractFromBridge.sol";

abstract contract AbstractStaticFromBridge is AbstractFromBridge {

    /**
     * Address (Ethereum format) of the token this FromBridge serves.
     */
    address public fromToken;

    modifier validateFromToken(address fromToken_, string memory errorMessage) {
        require(fromToken_ == fromToken, errorMessage);
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(address validator_, address fromToken_) AbstractFromBridge(validator_) {
        fromToken = fromToken_;
    }

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.getTokenUri" to add fromToken validation.
     * @return result of "super.getTokenUri" function.
     */
    function getTokenUri(address fromToken_, uint256 tokenId) public view virtual override
            validateFromToken(fromToken_, "getTokenUri: Only the token supported by this FromBridge is allowed to be called on")
            returns (bytes memory) {
        return super.getTokenUri(fromToken, tokenId);
    }

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.commit" to add fromToken validation.
     */
    function commit(
        address fromToken_,
        address toToken, address toBridge,
        address tokenOwner, uint256 requestNonce,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) public virtual override
    validateFromToken(fromToken_, "commit: Only the token supported by this FromBridge is allowed to be called on") {
        super.commit(
            fromToken_,
            toToken, toBridge,
            tokenOwner, requestNonce,
            tokenId,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature
        );
    }
}
