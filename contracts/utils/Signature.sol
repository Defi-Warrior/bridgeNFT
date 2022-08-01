//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title OwnerSignature
 * @dev This library is used for token owner's signature verification specific to the bridge protocol.
 */
library OwnerSignature {
    /**
     * @dev Verify owner's signature. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * @param tokenOwner The owner of the requested token.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param fromBridge Address (Ethereum format) of fromBridge.
     * @param toToken Address (Ethereum format) of toToken.
     * @param toBridge Address (Ethereum format) of toBridge.
     * @param requestNonce The request's nonce.
     * @param tokenId The ID of the requested token.
     * @param authnChallenge The challenge for user authentication to validator.
     * @param signature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * MESSAGE FORMAT:
     *      "RequestBridge" || fromToken || fromBridge || toToken || toBridge ||
     *      requestNonce || tokenId || authnChallenge(*)
     * Values marked with an asterisk (*) have dynamic size so they need to be hashed
     * before concatenating for security reason.
     * @return true if the signature is valid with respect to the owner's address
     * and given information.
     */
    function verify(
        address tokenOwner,
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        uint256 requestNonce, uint256 tokenId,
        bytes calldata authnChallenge,
        bytes memory signature
    ) internal view returns (bool) {
        // Craft signed message
        bytes memory message = abi.encodePacked("RequestBridge",
            fromToken, fromBridge,
            toToken, toBridge,
            requestNonce, tokenId,
            keccak256(authnChallenge)
        );

        return SignatureChecker.isValidSignatureNow(tokenOwner, ECDSA.toEthSignedMessageHash(message), signature);
    }
}

/**
 * @title ValidatorSignature
 * @dev This library is used for validator's signature verification specific to the bridge protocol.
 */
library ValidatorSignature {
    /**
     * @dev Verify validator's signature. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * @param validator Address (Ethereum format) of validator.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param fromBridge Address (Ethereum format) of fromBridge.
     * @param toToken Address (Ethereum format) of toToken.
     * @param toBridge Address (Ethereum format) of toBridge.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param tokenUri The URI of the request token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param signature This signature was signed by the validator after verifying
     * that the requester is the token's owner and ToBridge is approved on this token.
     * The owner will use this signature at FromBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * MESSAGE FORMAT:
     *      "Commit" || fromToken || fromBridge || toToken || toBridge ||
     *      tokenOwner || tokenId || tokenUri(*) || commitment || requestTimestamp
     * Values marked with an asterisk (*) have dynamic size so they need to be hashed
     * before concatenating for security reason.
     * @return true if the signature is valid with respect to the validator's address
     * and given information.
     */
    function verify(
        address validator,
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner,
        uint256 tokenId, bytes memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        // Craft signed message
        bytes memory message = abi.encodePacked("Commit",
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            keccak256(tokenUri),
            commitment, requestTimestamp
        );

        return SignatureChecker.isValidSignatureNow(validator, ECDSA.toEthSignedMessageHash(message), signature);
    }
}
