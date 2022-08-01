//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IDefiWarriorFromBridge.sol";
import "../../AbstractStaticFromBridge.sol";

import "./interfaces/IWarrior.sol";
import "./interfaces/IBodyPart.sol";

contract DefiWarriorFromBridge is IDefiWarriorFromBridge, AbstractStaticFromBridge {

    /**
     * @dev Constructor
     */
    constructor(address validator_, address fromToken_) AbstractStaticFromBridge(validator_, fromToken_) {}

    /**
     * @dev See AbstractStaticFromBridge.
     * Emit the information needed for owner to acquire new token at ToBridge:
     * - 
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
        super._emitEvents(
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, requestNonce,
            tokenId, tokenUri,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);

        // emit warrior id, body parts id
    }
}
