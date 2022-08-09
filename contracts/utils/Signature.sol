//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title OwnerSignature
 * @dev This library is used for token owner's signature verification specific to the bridge protocol.
 */
library OwnerSignature {
    struct MessageContainer {
        uint256 fromChainId;
        address fromToken;
        address fromBridge;
        uint256 toChainId;
        address toToken;
        address toBridge;
        uint256 requestNonce;
        uint256 tokenId;
        bytes   authnChallenge;
    }

    /**
     * @dev Verify owner's signature.
     * @param tokenOwner The owner of the requested token.
     * @param messageContainer Consists of:
     * - fromChainId: Chain ID of the origin blockchain.
     * - fromToken: Address (Ethereum format) of fromToken.
     * - fromBridge: Address (Ethereum format) of fromBridge.
     * - toChainId: Chain ID of the destination blockchain.
     * - toToken: Address (Ethereum format) of toToken.
     * - toBridge: Address (Ethereum format) of toBridge.
     * - requestNonce: The request's nonce.
     * - tokenId: The ID of the requested token.
     * - authnChallenge: The challenge for user authentication to validator.
     * @param signature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * @return true if the signature is valid with respect to the owner's address
     * and given information.
     */
    function verify(
        address tokenOwner,
        MessageContainer memory messageContainer,
        bytes memory signature
    ) internal view returns(bool) {
        bytes32 messageHash = _toMessageHash(messageContainer);

        return SignatureChecker.isValidSignatureNow(tokenOwner, messageHash, signature);
    }

    /**
     * @dev Craft message hash from container. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * MESSAGE FORMAT:
     *      "RequestBridge" || fromChainId || fromToken || fromBridge || toChainId || toToken || toBridge ||
     *      requestNonce || tokenId || authnChallenge(*)
     * Values marked with an asterisk (*) have dynamic size so they need to be hashed
     * before concatenating for security reason.
     * @return The message hash.
     */
    function _toMessageHash(MessageContainer memory messageContainer) private pure returns(bytes32) {
        return ECDSA.toEthSignedMessageHash( abi.encodePacked("RequestBridge",
            messageContainer.fromChainId, messageContainer.fromToken, messageContainer.fromBridge,
            messageContainer.toChainId, messageContainer.toToken, messageContainer.toBridge,
            messageContainer.requestNonce, messageContainer.tokenId,
            keccak256(messageContainer.authnChallenge)) );
    }
}

/**
 * @title ValidatorSignature
 * @dev This library is used for validator's signature verification specific to the bridge protocol.
 */
library ValidatorSignature {
    struct MessageContainer {
        uint256 fromChainId;
        address fromToken;
        address fromBridge;
        uint256 toChainId;
        address toToken;
        address toBridge;
        address tokenOwner;
        uint256 tokenId;
        bytes   tokenUri;
        bytes32 commitment;
        uint256 requestTimestamp;
    }

    /**
     * @dev Verify validator's signature.
     * @param validator Address (Ethereum format) of validator.
     * @param messageContainer Consists of:
     * - fromChainId: Chain ID of the origin blockchain.
     * - fromToken: Address (Ethereum format) of fromToken.
     * - fromBridge: Address (Ethereum format) of fromBridge.
     * - toChainId: Chain ID of the destination blockchain.
     * - toToken: Address (Ethereum format) of toToken.
     * - toBridge: Address (Ethereum format) of toBridge.
     * - tokenOwner: The owner of the requested token.
     * - tokenId: The ID of the requested token.
     * - tokenUri: The URI of the request token.
     * - commitment: The validator's commitment.
     * - requestTimestamp: The timestamp when the validator received request.
     * @param signature This signature was signed by the validator after verifying
     * that the requester is the token's owner and ToBridge is approved on this token.
     * The owner will use this signature at FromBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * For message format, see "_toMessageHash" function.
     * @return true if the signature is valid with respect to the validator's address
     * and given information.
     */
    function verify(
        address validator,
        MessageContainer memory messageContainer,
        bytes memory signature
    ) internal view returns(bool) {
        bytes32 messageHash = _toMessageHash(messageContainer);

        return SignatureChecker.isValidSignatureNow(validator, messageHash, signature);
    }

    /**
     * @dev Craft message hash from container. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * MESSAGE FORMAT:
     *      "Commit" || fromChainId || fromToken || fromBridge || toChainId || toToken || toBridge ||
     *      tokenOwner || tokenId || tokenUri(*) || commitment || requestTimestamp
     * Values marked with an asterisk (*) have dynamic size so they need to be hashed
     * before concatenating for security reason.
     * @return The message hash.
     */
    function _toMessageHash(MessageContainer memory messageContainer) private pure returns(bytes32) {
        return ECDSA.toEthSignedMessageHash( abi.encodePacked("Commit",
            messageContainer.fromChainId, messageContainer.fromToken, messageContainer.fromBridge,
            messageContainer.toChainId, messageContainer.toToken, messageContainer.toBridge,
            messageContainer.tokenOwner, messageContainer.tokenId,
            keccak256(messageContainer.tokenUri),
            messageContainer.commitment, messageContainer.requestTimestamp) );
    }
}
