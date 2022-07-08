//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ToBridge.sol";

/**
 * @title ClaimToBridge
 * @dev This contract adds claim functionality to base ToBridge contract.
 */
contract ClaimToBridge is ToBridge {

    struct ClaimDetail {
        address claimer;
        uint256 tokenId;
        string  tokenUri;
        uint256 requestTimestamp;
        uint256 waitingDurationForOldTokenToBeProcessed;
        uint256 timestamp;
        uint256 waitingDurationToAcquireByClaim;
        uint256 escrow;
        bool    denied;
    }

    /**
     * - globalWaitingDurationToAcquireByClaim: The duration the token owner needs
     * to wait in order to acquire by claim, starting from claim's timestamp
     * determined by FromBridge. This is to give the validator time to deny claim.
     * - minimumEscrow: Users must send an amount of the chain's native currency
     * (an escrow) when claimming.
     * So this variable specifies the minimum value of that amount.
     */
    uint256 public globalWaitingDurationToAcquireByClaim;
    uint256 public minimumEscrow;

    /**
     * Mapping from validator's commitment to claim.
     *
     * Even if there were multiple tokens with same token ID requested to be bridged,
     * the commitment would be different each time (with high probability). Therefore commitment
     * could be used as an identity for every requests, acquirements and claims.
     */
    mapping(bytes32 => ClaimDetail) private _claims;

    event Claim(
        address indexed claimer,
        uint256 indexed tokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeProcessed,
        uint256         claimTimestamp,
        uint256         waitingDurationToAcquireByClaim,
        uint256         escrow);

    event AcquireByClaim(
        address indexed acquirer,
        uint256 indexed oldTokenId,
        uint256         newTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeProcessed,
        uint256         claimTimestamp,
        uint256         waitingDurationToAcquireByClaim,
        uint256         acquirementTimestamp);

    event Deny(
        address indexed claimer,
        uint256 indexed tokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeProcessed,
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
        uint256 globalWaitingDurationForOldTokenToBeProcessed_,
        uint256 globalWaitingDurationToAcquireByClaim_,
        uint256 minimumEscrow_
    ) public virtual onlyOwner reinitializer(2) {
        fromToken = fromToken_;
        fromBridge = fromBridge_;
        validator = validator_;
        globalWaitingDurationForOldTokenToBeProcessed = globalWaitingDurationForOldTokenToBeProcessed_;
        globalWaitingDurationToAcquireByClaim = globalWaitingDurationToAcquireByClaim_;
        minimumEscrow = minimumEscrow_;

        toToken = ToNFT(toToken_);
        toBridge = address(this);

        _initialized = true;
    }

    /**
     * @dev "globalWaitingDurationToAcquireByClaim" setter
     */
    function setGlobalWaitingDurationToAcquireByClaim(uint256 newGlobalWaitingDurationToAcquireByClaim) external onlyOwner {
        globalWaitingDurationToAcquireByClaim = newGlobalWaitingDurationToAcquireByClaim;
    }

    /**
     * @dev "minimumEscrow" setter
     */
    function setMinimumEscrow(uint256 newMinimumEscrow) external onlyOwner {
        minimumEscrow = newMinimumEscrow;
    }

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
    ) external payable onlyInitialized nonReentrant {
        // Check all requirements to claim.
        _checkClaimRequiments(
            tokenOwner, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            validatorSignature);

        // Rename variables for readability.
        address claimer = tokenOwner;
        uint256 waitingDurationForOldTokenToBeProcessed = globalWaitingDurationForOldTokenToBeProcessed;
        uint256 timestamp = block.timestamp;
        uint256 waitingDurationToAcquireByClaim = globalWaitingDurationToAcquireByClaim;
        uint256 escrow = msg.value;

        // Save claim.
        _saveClaim(
            claimer, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            timestamp,
            waitingDurationToAcquireByClaim,
            escrow);

        // Emit event.
        emit Claim(
            claimer, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            timestamp,
            waitingDurationToAcquireByClaim,
            escrow);
    }

    /**
     * @dev Check all requirements to claim token. If an inheriting contract has more
     * requirements, when overriding it should first call super._checkClaimRequiments(...)
     * then add its own requirements.
     * Parameters are the same as "claim" function.
     *
     * Currently the checks are:
     * - Validator's signature.
     * - The claim does not exist (i.e. the "claim" function is called the first time).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     * - The message sender is the token owner.
     * - The sended escrow value is at least "minimumEscrow".
     * - The commit transaction at FromBridge is finalized.
     */
    function _checkClaimRequiments(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal view virtual {
        // Verify validator's signature.
        require(
            _verifyValidatorSignature(
                tokenOwner, tokenId,
                tokenUri,
                commitment, requestTimestamp,
                validatorSignature),
            "Claim: Invalid validator signature");

        // The claim must not exist.
        require(!_existsClaim(commitment), "Claim: Claim already exists");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Claim: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "Claim: Token has been denied by the validator");

        // By policy, token owners must acquire by themselves.
        require(msg.sender == tokenOwner, "Claim: Token can only be acquired by its owner");

        // Revert if sended escrow is not enough.
        require(msg.value >= minimumEscrow, "Claim: Sended value is not enough for escrow");

        // Revert if user did not wait enough time.
        require(block.timestamp > requestTimestamp + globalWaitingDurationForOldTokenToBeProcessed,
            "Claim: Elapsed time from request is not enough");
    }

    /**
     * @dev Save claim to contract's storage.
     */
    function _saveClaim(
        address claimer, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        uint256 waitingDurationForOldTokenToBeProcessed,
        uint256 timestamp,
        uint256 waitingDurationToAcquireByClaim,
        uint256 escrow
    ) internal {
        bool denied = false;

        _claims[commitment] = ClaimDetail(
            claimer, tokenId,
            tokenUri,
            requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            timestamp,
            waitingDurationToAcquireByClaim,
            escrow, denied);
    }

    /**
     * @dev This function is called by users after claimming to acquire new token without
     * providing the secret of the commitment.
     * @param commitment The validator's commitment. There is only one claim per commitment
     * and vice versa, so the commitment could act as the claim's identity.
     */
    function acquireByClaim(bytes32 commitment) external onlyInitialized nonReentrant {
        // Retrieve claim.
        ClaimDetail storage claimDetail = _claims[commitment];

        // Check all requirements to acquire by claim.
        _checkAcquireByClaimRequiments(commitment, claimDetail);

        // Mint a new token corresponding to the old one.
        uint256 newTokenId = _mint(claimDetail.claimer, claimDetail.tokenUri);

        // Return escrow back to claimer.
        payable(claimDetail.claimer).transfer(claimDetail.escrow);

        // Rename variables for readability.
        address         acquirer                                = claimDetail.claimer;
        uint256         oldTokenId                              = claimDetail.tokenId;
        string storage  tokenUri                                = claimDetail.tokenUri;
        uint256         requestTimestamp                        = claimDetail.requestTimestamp;
        uint256         waitingDurationForOldTokenToBeProcessed = claimDetail.waitingDurationForOldTokenToBeProcessed;
        uint256         claimTimestamp                          = claimDetail.timestamp;
        uint256         waitingDurationToAcquireByClaim         = claimDetail.waitingDurationToAcquireByClaim;
        uint256         acquirementTimestamp                    = block.timestamp;

        // Save acquirement.
        _saveAcquirement(
            acquirer,
            oldTokenId, newTokenId,
            tokenUri,
            commitment, requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            acquirementTimestamp);

        // Emit event.
        emit AcquireByClaim(
            acquirer,
            oldTokenId, newTokenId,
            tokenUri,
            commitment, requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            claimTimestamp,
            waitingDurationToAcquireByClaim,
            acquirementTimestamp);
    }

    /**
     * @dev Check all requirements to acquire token by claim. If an inheriting contract has more
     * requirements, when overriding it should first call super._checkAcquireByClaimRequiments(...)
     * then add its own requirements.
     * @param commitment The validator's commitment.
     * @param claimDetail The detail of the claim retrieved using the given commitment.
     *
     * Currently the checks are:
     * - The claim exists (i.e. the "claim" function was called before "acquireByClaim" function).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     * - The message sender is the claimer (token owner).
     * - All time-related requirements are delegated to "_checkAcquireByClaimTimeRequiments" function.
     */
    function _checkAcquireByClaimRequiments(bytes32 commitment, ClaimDetail storage claimDetail) internal view virtual {
        // The claim must exist.
        require(_existsClaim(commitment), "AcquireByClaim: Claim does not exist");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "AcquireByClaim: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "AcquireByClaim: Token has been denied by the validator");

        // By policy, token owners must acquire by themselves.
        // The claimer is token owner (verified when claimming).
        require(msg.sender == claimDetail.claimer, "AcquireByClaim: Token can only be acquired by its owner");

        // Check all time-related requirements.
        _checkAcquireByClaimTimeRequiments(claimDetail);
    }

    /**
     * @dev All time-related requirements are separated from "_checkAcquireByClaimRequiments"
     * function into this function for the purpose of functionality extension (e.g. pausability).
     * If a contract inherits this contract and adds some time-related logic, it shall override
     * this function.
     *
     * Currently the checks are:
     * - The time elapsed after claimming is larger than "waitingDurationToAcquireByClaim",
     * which is determined when claimming.
     */
    function _checkAcquireByClaimTimeRequiments(ClaimDetail storage claimDetail) internal view virtual {
        // Revert if user did not wait enough time.
        require(block.timestamp > claimDetail.timestamp + claimDetail.waitingDurationToAcquireByClaim,
            "AcquireByClaim: Elapsed time from claim is not enough");
    }

    /**
     * @dev This function may be called by the validator after a claim was submitted by a user,
     * in order to prevent that user from acquiring new token afterwards.
     * The whole denying functionality is to prevent user's double spending. To not get distrusted
     * by users, this function should only be called in the case the old token has not been
     * processed at FromBridge.
     * @param commitment The validator's commitment. There is only one claim per commitment
     * and vice versa, so the commitment could act as the claim's identity.
     */
    function deny(bytes32 commitment)
    external onlyInitialized onlyValidator("Deny: Only validator is allowed to deny") {
        // Retrieve claim.
        ClaimDetail storage claimDetail = _claims[commitment];

        // Check all requirements to acquire by claim.
        _checkDenyRequiments(commitment, claimDetail);

        // Modify contract's state to reflect the denial.
        _deny(commitment);

        // Send escrow to validator.
        payable(validator).transfer(claimDetail.escrow);

        // Rename variables for readability.
        address         claimer                                 = claimDetail.claimer;
        uint256         tokenId                                 = claimDetail.tokenId;
        string storage  tokenUri                                = claimDetail.tokenUri;
        uint256         requestTimestamp                        = claimDetail.requestTimestamp;
        uint256         waitingDurationForOldTokenToBeProcessed = claimDetail.waitingDurationForOldTokenToBeProcessed;
        uint256         claimTimestamp                          = claimDetail.timestamp;
        uint256         denialTimestamp                         = block.timestamp;
        uint256         waitingDurationToAcquireByClaim         = claimDetail.waitingDurationToAcquireByClaim;

        // Emit event.
        emit Deny(
            claimer, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            claimTimestamp,
            denialTimestamp,
            waitingDurationToAcquireByClaim);
    }

    /**
     * @dev Check all requirements to deny claim. If an inheriting contract has more
     * requirements, when overriding it should first call super._checkDenyRequiments(...)
     * then add its own requirements.
     * @param commitment The validator's commitment.
     * @param claimDetail The detail of the claim retrieved using the given commitment.
     *
     * Currently the checks are:
     * - The claim exists (i.e. the "claim" function was called before "acquireByClaim" function).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     */
    function _checkDenyRequiments(bytes32 commitment, ClaimDetail storage claimDetail) internal view virtual {
        // The claim must exist.
        require(_existsClaim(commitment), "Deny: Claim does not exist");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Deny: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "Deny: Token has been denied by the validator");

        // Warning supressing purpose.
        // The "claimDetail" variable is not used for now but still in parameters to cover the case
        // there is any inheriting contract overrides this function and uses the claim's data.
        if (false) { claimDetail; }
    }

    /**
     * @dev This function is the core of denial process. Inheriting contract shall override
     * this function if it adds more logic.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     */
    function _deny(bytes32 commitment) internal virtual {
        _claims[commitment].denied = true;
    }

    /**
     * @dev Check if the claim identified by the specified commitment has been denied
     * by the validator.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     * @return true if the claim has already been denied.
     */
    function _isDenied(bytes32 commitment) internal view returns (bool) {
        return _claims[commitment].denied;
    }

    /**
     * @dev Check if the claim identified by the specified commitment exists.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     * @return true if the claim exists.
     */
    function _existsClaim(bytes32 commitment) internal view returns (bool) {
        return _claims[commitment].timestamp != 0;
    }
}