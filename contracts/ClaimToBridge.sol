//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ToBridge.sol";

/**
 * @title ClaimToBridge
 * @dev This contract adds claim functionality to base ToBridge.
 */
contract ClaimToBridge is ToBridge {

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
     * The duration the token owner needs to wait in order to acquire by claim,
     * starting from claim's timestamp determined by FromBridge. This is to give
     * the validator time to deny claim.
     */
    uint256 public globalWaitingDurationToAcquireByClaim;

    /**
     * Mapping from validator's commitment to claim.
     *
     * Even if there were multiple tokens with same token ID requested to be bridged,
     * the commitment would be different each time (with high probability). Therefore commitment
     * could be used as an identity for every requests, acquirements, claims, and denials.
     */
    mapping(bytes32 => ClaimDetail) private _claims;

    /**
     * Mapping from validator's commitment to denial.
     */
    mapping(bytes32 => bool) private _denials;

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
    ) public virtual onlyOwner reinitializer(2) {
        fromToken = fromToken_;
        fromBridge = fromBridge_;
        validator = validator_;
        globalWaitingDurationForOldTokenToBeBurned = globalWaitingDurationForOldTokenToBeBurned_;
        globalWaitingDurationToAcquireByClaim = globalWaitingDurationToAcquireByClaim_;

        toToken = ToNFT(toToken_);
        toBridge = address(this);

        _initialized = true;
    }

    /**
     * @dev Change globalWaitingDurationToAcquireByClaim
     */
    function setGlobalWaitingDurationToAcquireByClaim(uint256 newGlobalWaitingDurationToAcquireByClaim) external onlyOwner {
        globalWaitingDurationToAcquireByClaim = newGlobalWaitingDurationToAcquireByClaim;
    }
}