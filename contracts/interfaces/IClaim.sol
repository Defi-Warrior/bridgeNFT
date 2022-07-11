//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IClaim {
    /**
     * @return The current global time duration the token owner needs to wait in order to
     * acquire by claim, starting from claim's timestamp determined by ToBridge.
     */
    function globalWaitingDurationToAcquireByClaim() external view returns (uint256);

    /**
     * @return The minimum value of the native currency for escrow.
     */
    function minimumEscrow() external view returns (uint256);

    /**
     * @dev This function is called by users to claim that the old token has been processed
     * but they have not received the secret from the validator. Afterwards users may acquire
     * the new token by calling "acquireByClaim" function.
     * @param tokenOwner The owner of the old token.
     * @param tokenId The ID of the old token.
     * @param tokenUri The URI of the old token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function claim(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory validatorSignature
    ) external payable;

    /**
     * @dev This function is called by users after claimming to acquire new token without
     * providing the secret of the commitment.
     * @param commitment The validator's commitment. There is only one claim per commitment
     * and vice versa, so the commitment could act as the claim's identity.
     */
    function acquireByClaim(bytes32 commitment) external;

    /**
     * @dev This function may be called by the validator after a claim was submitted by a user,
     * in order to prevent that user from acquiring new token afterwards.
     * The whole denying functionality is to prevent user's double spending. To not get distrusted
     * by users, this function should only be called in the case the old token has not been
     * processed at FromBridge.
     * @param commitment The validator's commitment. There is only one claim per commitment
     * and vice versa, so the commitment could act as the claim's identity.
     */
    function deny(bytes32 commitment) external;
}