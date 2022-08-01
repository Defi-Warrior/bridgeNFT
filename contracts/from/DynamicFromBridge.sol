//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IDynamicFromBridge.sol";
import "./AbstractFromBridge.sol";

contract DynamicFromBridge is IDynamicFromBridge, AbstractFromBridge {

    /**
     * @dev Constructor
     */
    constructor(address validator_) AbstractFromBridge(validator_) {}

    /**
     * @dev See AbstractFromBridge.
     * Emit the information needed for owner to acquire new token at ToBridge:
     * - Token URI
     * - Commitment
     * - Request timestamp
     * - Validator's signature
     */
    function _emitEvents(
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner, uint256 requestNonce,
        uint256 tokenId, bytes memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual override {
        emit Commit(
            fromToken,
            toToken, toBridge,
            tokenOwner, requestNonce,
            tokenId, tokenUri,
            commitment, requestTimestamp,
            validatorSignature);
    }
}
