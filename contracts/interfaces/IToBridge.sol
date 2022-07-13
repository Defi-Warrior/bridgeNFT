//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IToBridge {
    /**
     * @dev This function is called by users to get new token corresponding to the old one.
     * @param tokenOwner The owner of the old token.
     * @param tokenId The ID of the old token.
     * @param commitment The validator's commitment.
     * @param secret The validator's revealed value.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function acquire(
        address tokenOwner, uint256 tokenId,
        uint32[30] memory warriorAttributes,
        uint32[20][6] memory bodypartAttributes,
        bytes32 commitment, bytes calldata secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) external;
}