//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./events/IFromBridgeEvents.sol";

interface IFromBridge is IFromBridgeEvents {
    struct Origin {
        address fromToken;
        address fromBridge;
    }

    struct Destination {
        address toToken;
        address toBridge;
    }

    struct RequestId {
        address tokenOwner;
        uint256 requestNonce;
    }

    struct TokenInfo {
        uint256 tokenId;
        bytes   tokenUri;
    }

    /**
     * @dev "validator" getter.
     */
    function validator() external view returns (address);
        
    /**
     * @dev Users call to get nonce before requesting the validator for token bridging.
     * @return The current request nonce associated with the message sender.
     */
    function getRequestNonce() external view returns (uint256);

    /**
     * @dev After receive a request from a user, the validator calls to get the right nonce
     * then compare with the nonce sent by that user.
     * @param tokenOwner The owner of the requested token.
     * @return The current request nonce associated with that owner.
     */
    function getRequestNonce(address tokenOwner) external view returns (uint256);

    /**
     * @dev URI management scheme may vary for each token. So child contracts MAY
    * implement the URI management scheme suitable for their respective tokens.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param tokenId The token ID.
     * @return The token URI.
     */
    function getTokenUri(address fromToken, uint256 tokenId) external view returns (bytes memory);

    /**
     * Users call this function after the commit transaction to retrieve the validator's signature.
     * @param requestNonce: The request's nonce.
     * @return The validator signature associated with the request determined by
     * the token owner who is the message sender and the specified nonce.
     */
    function getValidatorSignature(uint256 requestNonce)
        external view returns (bytes memory);

    /**
     * @dev This function is used for inspection purpose and MUST be made only callable
     * by account(s) with administrative rights.
     * @param requestId Consists of:
     * - tokenOwner: The owner of the requested token.
     * - requestNonce: The request's nonce.
     * @return Address (Ethereum format) of the validator who processed the specified request
     * and the associated signature.
     */
    function getValidatorSignature(RequestId calldata requestId)
        external view returns (address, bytes memory);

    /**
     * @dev This function is called only by the validator to submit the commitment
     * and process the token at the same time. The token will be processed if this transaction
     * is successfully executed. The processing action is either permanent burning or holding
     * custody of the token, depending on implementation.
     * @param fromToken Address (Ethereum format) of fromToken.
     * @param destination Consists of:
     * - toToken: Address (Ethereum format) of toToken.
     * - toBridge: Address (Ethereum format) of toBridge.
     * @param requestId Consists of:
     * - tokenOwner: The owner of the requested token.
     * - requestNonce: The request's nonce.
     * @param tokenId The ID of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param authnChallenge The challenge for user authentication to validator.
     * @param ownerSignature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * For message format, see "OwnerSignature" library in "Signature.sol" contract.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * The owner will use this signature at ToBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * For message format, see "ValidatorSignature" library in "Signature.sol" contract.
     */
    function commit(
        address fromToken,
        Destination calldata destination,
        RequestId calldata requestId,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) external;
}
