//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ToNFT.sol";
import "./utils/Signature.sol";

/**
 * @title ToBridge
 * @dev This contract carries out the second part of the process of bridging (converting)
 * user's ERC721 NFTs from another chain to this chain. Both chains are Ethereum-based.
 * The second part is essentially minting new NFTs corresponding to the old ones for users.
 */
contract ToBridge is Ownable, Initializable, Pausable, ReentrancyGuard {

    struct AcquirementDetail {
        address acquirer;
        uint256 oldTokenId;
        uint256 newTokenId;
        string  tokenUri;
        uint256 requestTimestamp;
        uint256 waitingDurationForOldTokenToBeBurned;
        uint256 timestamp;
    }

    struct ClaimDetail {
        address claimer;
        uint256 oldTokenId;
        string  tokenUri;
        uint256 requestTimestamp;
        uint256 waitingDurationForOldTokenToBeBurned;
        uint256 timestamp;
        uint256 waitingDurationToAcquireByClaim;
    }

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     *
     * - fromBridge: Address of the contract that carries out the first part of the bridging process.
     * fromToken contract and fromBridge contract must be on the same chain.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of this contract.
     * toToken contract and toBridge contract must be on the same chain.
     *
     * - validator: (Blockchain) Address of the validator that confirms request on the other chain
     * and provides user signature to obtain the new token on this chain.
     *
     * - globalWaitingDurationForOldTokenToBeBurned: The duration the token owner needs to wait
     * in order to acquire or claim, starting from request's timestamp determined by the validator.
     * This is to ensure that the "commitAndBurn" transaction on the old chain is finalized.
     *
     * - globalWaitingDurationToAcquireByClaim: The duration the token owner needs to wait in
     * order to acquire by claim, starting from claim's timestamp determined by FromBridge. This is
     * to give the validator time to deny claim.
     */
    address public fromToken;
    address public fromBridge;
    ToNFT   public toToken;
    address public toBridge;
    address public validator;
    uint256 public globalWaitingDurationForOldTokenToBeBurned;
    uint256 public globalWaitingDurationToAcquireByClaim;

    /**
     * Mapping from validator's commitment to acquirement.
     * An acquirement will only be stored if a transaction call to "acquire" function succeeds.

     * Even if there were multiple tokens with same token ID requested to be bridged,
     * the commitment would be different each time (with high probability). Therefore commitment
     * could be used as an identity for every requests, acquirements, claims, and denials.
     */
    mapping(bytes32 => AcquirementDetail) private _acquirements;

    /**
     * Mapping from validator's commitment to claim.
     */
    mapping(bytes32 => ClaimDetail) private _claims;

    /**
     * Mapping from validator's commitment to denial.
     */
    mapping(bytes32 => bool) private _denials;

    event Acquire(
        address indexed acquirer,
        uint256 indexed oldTokenId,
        uint256         newTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeBurned,
        uint256         acquirementTimestamp);

    event Claim(
        address indexed claimer,
        uint256 indexed oldTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeBurned,
        uint256         claimTimestamp,
        uint256         waitingDurationToAcquireByClaim);

    event AcquireByClaim(
        address indexed acquirer,
        uint256 indexed oldTokenId,
        uint256         newTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeBurned,
        uint256         claimTimestamp,
        uint256         waitingDurationToAcquireByClaim,
        uint256         acquirementTimestamp);

    event Deny(
        address indexed claimer,
        uint256 indexed oldTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeBurned,
        uint256         claimTimestamp,
        uint256         denialTimestamp,
        uint256         waitingDurationToAcquireByClaim);

    modifier onlyValidator(string memory errorMessage) {
        require(msg.sender == validator, errorMessage);
        _;
    }

    /**
     * @dev To be called immediately after contract deployment. Replaces constructor.
     */
    function initialize(
        address fromToken_,
        address fromBridge_,
        address toToken_,
        address validator_,
        uint256 globalWaitingDurationForOldTokenToBeBurned_,
        uint256 globalWaitingDurationToAcquireByClaim_
    ) public virtual onlyOwner initializer {
        fromToken = fromToken_;
        fromBridge = fromBridge_;
        validator = validator_;
        globalWaitingDurationForOldTokenToBeBurned = globalWaitingDurationForOldTokenToBeBurned_;
        globalWaitingDurationToAcquireByClaim = globalWaitingDurationToAcquireByClaim_;

        toToken = ToNFT(toToken_);
        toBridge = address(this);
    }

    /**
     * @dev Change validator
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev Change globalWaitingDurationForOldTokenToBeBurned
     */
    function setGlobalWaitingDurationForOldTokenToBeBurned(uint256 newGlobalWaitingDurationForOldTokenToBeBurned) external onlyOwner {
        globalWaitingDurationForOldTokenToBeBurned = newGlobalWaitingDurationForOldTokenToBeBurned;
    }

    /**
     * @dev Change globalWaitingDurationToAcquireByClaim
     */
    function setGlobalWaitingDurationToAcquireByClaim(uint256 newGlobalWaitingDurationToAcquireByClaim) external onlyOwner {
        globalWaitingDurationToAcquireByClaim = newGlobalWaitingDurationToAcquireByClaim;
    }

    // /**
    //  * @dev User calls this function to get new token corresponding to the old one.
    //  * @param requestId Consists of token owner's address, token's ID and nonce.
    //  * @param requestTimestamp The request timestamp stored in FromBridge.
    //  * @param signature This signature was signed by the validator to confirm the request
    //  * after seeing the "Request" event emitted from FromBridge.
    //  */
    function acquire(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, bytes calldata secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) external whenNotPaused nonReentrant {
        // Verify validator's signature
        require(
            _verifyValidatorSignature(
                tokenOwner, tokenId,
                tokenUri,
                commitment, requestTimestamp,
                validatorSignature),
            "Invalid validator signature");

        // The token must not have been acquired
        require(!_isAcquired(tokenId), "Token has been acquired");

        // By policy, token owners must acquire by themselves
        require(msg.sender == tokenOwner, "Token can only be acquired by its owner");

        // Revert if user did not wait enough time
        require(block.timestamp > requestTimestamp + globalWaitingDurationForOldTokenToBeBurned, "Elapsed time from request is not enough");

        // Revert if request had been rejected by validator
        require(!_isRejected(), "This request for token acquirement has been rejected by the validator");

        // Save acquirement
        uint256 waitingDurationForOldTokenToBeBurned = globalWaitingDurationForOldTokenToBeBurned;
        uint256 acquirementTimestamp = block.timestamp;
        _acquirements[tokenId] = AcquirementDetail(tokenOwner,
                                                                requestTimestamp,
                                                                waitingDurationForOldTokenToBeBurned,
                                                                acquirementTimestamp);

        // Mint a new token corresponding to the old one
        toToken.mint(tokenOwner, tokenId);

        // Emit event
        emit Acquire(
            tokenOwner,
            tokenId,
            nonce,
            requestTimestamp,
            waitingDurationForOldTokenToBeBurned,
            acquirementTimestamp);
    }

    // /**
    //  * @dev In case the validator noticed that the confirmation transaction sent to fromBridge had not
    //  * been finalized (i.e not included in some block that is, for example, 6 blocks backward
    //  * from the newest block) after a specific period of time (e.g 10 minutes), the validator would
    //  * call this function to reject user to acquire token by using that unconfirmed request.
    //  * 
    //  * It should be noted that the request sent to this function must be the latest request
    //  * corresponding to that token processed by fromBridge. Because technically what this function
    //  * does is just increasing the latest nonce by 1, thus making the nonces unsynchronized.
    //  *
    //  * @param requestId Consists of token owner's address, token's ID and nonce.
    //  */
    // function rejectAcquirementByRequest(RequestId calldata requestId)
    //         external onlyValidator("Only validator is allowed to reject request") {
    //     // The token must not have been acquired
    //     require(!_isAcquired(requestId.tokenId), "Token has been acquired");

    //     // Make this nonce unsynchronized (i.e. unequal) with the nonce stored in FromBridge,
    //     // so that user could not acquire token using the nonce in this request.
    //     // Note that, by increment by 1, this nonce will auto resynchronized with the other after user
    //     // claims his/her token back at FromBridge.
    //     _latestNonces[requestId.tokenOwner][requestId.tokenId]++;

    //     // Emit event
    //     uint256 rejectTimestamp = block.timestamp;
    //     emit Reject(requestId.tokenOwner, requestId.tokenId, requestId.nonce, rejectTimestamp);
    // }

    // /**
    //  * @dev The validator could reallow acquirement by a request that was previously rejected 
    //  * @param requestId Consists of token owner's address, token's ID and nonce.
    //  * @param requestTimestamp The request's timestamp
    //  */
    // function forceMintAfterReject(RequestId calldata requestId, uint256 requestTimestamp)
    //         external onlyValidator("Only validator is allowed to force mint") {
    //     // The token must not have been acquired
    //     require(!_isAcquired(requestId.tokenId), "Token has been acquired");

    //     // Save acquirement
    //     // Set "waitingDurationToAcquire" to 0 instead of "globalWaitingDurationToAcquire"
    //     // to distinguish force minting from normal acquirement.
    //     uint256 waitingDurationToAcquire = 0;
    //     uint256 forceMintTimestamp = block.timestamp;
    //     _acquirements[requestId.tokenId] = AcquirementDetail(requestId.tokenOwner,
    //                                                             requestTimestamp,
    //                                                             waitingDurationToAcquire,
    //                                                             forceMintTimestamp);

    //     // Resynchronize nonce. The nonce value after subtract acts as the nonce
    //     // used to acquire
    //     _latestNonces[requestId.tokenOwner][requestId.tokenId]--;

    //     // Mint a new token corresponding to the old one
    //     toToken.mint(requestId.tokenOwner, requestId.tokenId);

    //     // Emit event
    //     emit ForceMint(
    //         requestId.tokenOwner,
    //         requestId.tokenId,
    //         requestId.nonce,
    //         forceMintTimestamp);
    // }

    // /**
    //  * @dev The token had been acquired if and only if the "_acquirements" mapping would
    //  * have stored non-default values in the AcquirementDetail struct. The default value
    //  * of every storage slot is 0.
    //  * @param tokenId The token's ID on old chain.
    //  * @return true if the token has already been acquired.
    //  */
    // function _isAcquired(uint256 tokenId) internal view returns (bool) {
    //     return _acquirements[tokenId].timestamp != 0;
    // }

    // /**
    //  * @dev The request has been rejected by the validator if and only if the nonce coming from the
    //  * request (which originated from FromBridge) and the nonce stored in "_latestNonces"
    //  * are unequal.
    //  * @param requestId Consists of token owner's address, token's ID and nonce.
    //  * @return true if the request has been rejected by the validator.
    //  */
    // function _isRejected(RequestId calldata requestId) internal view returns (bool) {
    //     return requestId.nonce != _latestNonces[requestId.tokenOwner][requestId.tokenId];
    // }

    /**
     * @dev Wrapper of "verifyValidatorSignature" function in "Signature.sol" contract,
     * for code readability purpose in "acquire" and "claim" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param tokenUri The URI of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param signature The signature signed by the validator.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function _verifyValidatorSignature(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        return Signature.verifyValidatorSignature(
            address(fromToken), fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            validator,
            signature);
    }
}
