//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Signature {

    /**
     * @dev Verify owner's signature. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param fromBridge Address (Ethereum format) of fromBridge.
     * @param toToken Address (Ethereum format) of toToken.
     * @param toBridge Address (Ethereum format) of toBridge.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param signature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * MESSAGE FORMAT:
     *      "RequestTokenBurn" || fromToken || fromBridge || toToken || toBridge ||
     *      tokenOwner || tokenId
     */
    function verifyOwnerSignature(
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner, uint256 tokenId,
        bytes memory signature
    ) internal view returns (bool) {
        // Craft signed message
        bytes memory message = abi.encodePacked("RequestTokenBurn",
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId
        );

        return _verifySignature(tokenOwner, message, signature);
    }

    /**
     * @dev Verify validator's signature. Right now the message is crafted using plain
     * string concatenation. Will upgrade to EIP-712 later.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param fromBridge Address (Ethereum format) of fromBridge.
     * @param toToken Address (Ethereum format) of toToken.
     * @param toBridge Address (Ethereum format) of toBridge.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param tokenUri The URI of the request token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param validator Address (Ethereum format) of validator.
     * @param signature This signature was signed by the validator after verifying
     * that the requester is the token's owner and ToBridge is approved on this token.
     * The owner will use this signature at FromBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * MESSAGE FORMAT:
     *      "Commit" || fromToken || fromBridge || toToken || toBridge ||
     *      tokenOwner || tokenId || tokenUri || commitment || requestTimestamp
     */
    function verifyValidatorSignature(
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        address validator,
        bytes memory signature
    ) internal view returns (bool) {
        // Craft signed message
        bytes memory message = abi.encodePacked("Commit",
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            // The "tokenUri" variable's size is dynamic so it needs to be hashed
            // when crafting message for security reason.
            // Here abi.encodePacked is used only to convert string to bytes.
            keccak256(abi.encodePacked(tokenUri)),
            commitment, requestTimestamp
        );

        return _verifySignature(validator, message, signature);
    }

    function _verifySignature(
        address signer,
        bytes memory message,
        bytes memory signature
    ) private view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer, ECDSA.toEthSignedMessageHash(message), signature);
    }
}