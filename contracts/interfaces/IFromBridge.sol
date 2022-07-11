//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFromBridge {
    /**
     * @return Address of the current validator.
     */
    function validator() external view returns (address);

    /**
     * @dev There are two cases that this function is called.
     * 1. Users call before requesting the validator for token bridging.
     * Because the validator will not accept a request without the right nonce.
     * Users could query only the nonces of their currently owned tokens.
     * 2. The validator calls after receive a request from a user, to check if
     * the nonce sent by that user is valid.
     * @param tokenId The ID of the requested token.
     * @return nonce The current request nonce associated with that owner and token ID.
     */
    function getRequestNonce(uint256 tokenId) external view returns (uint256);

    /**
     * @dev This function is called only by the validator to submit the commitment
     * and process the token at the same time. The token will be processed if this transaction
     * is successfully executed. The processing action is either permanent burning or holding
     * custody of the token, depending on implementation.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param requestNonce The request's nonce.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param ownerSignature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * For message format, see "verifyOwnerSignature" function in "Signature.sol" contract.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * The owner will use this signature at ToBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function commit(
        address tokenOwner, uint256 tokenId,
        uint256 requestNonce,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) external;
}