//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events/IToBridgeEvents.sol";

interface IToBridge is IToBridgeEvents {
    struct Origin {
        uint256 fromChainId;
        address fromToken;
        address fromBridge;
    }

    struct Destination {
        uint256 toChainId;
        address toToken;
        address toBridge;
    }

    struct TokenInfo {
        uint256 tokenId;
        bytes   tokenUri;
    }

    /* ********************************************************************************************** */

    /**
     * @return Address of ToToken this ToBridge is associated with.
     */
    function getToToken() external view returns(address);

    /**
     * @return Address of the validator.
     */
    function getValidator() external view returns(address);

    /**
     * @return The duration the token owner needs to wait in order to acquire, starting from
     * request's timestamp determined by the validator. This is to ensure that
     * the "commit" transaction on the old chain is finalized.
     */
    function getGlobalWaitingDurationForOldTokenToBeProcessed() external view returns(uint256);

    /* ********************************************************************************************** */

    /**
     * @dev Check if ToBridge could mint new FromToken's tokens at the moment of calling.
     * ToBridge could be locked or revoked by FromToken and so does not have right to mint.
     *
     * This function SHOULD be called at the beginning of the bridge process to determine
     * whether token owners should request bridge or not. If false is returned, the token
     * owners should stop to prevent their tokens getting processed at FromBridge.
     * @return true if this FromBridge has right to mint new FromToken's token.
     */
    function isCurrentlyBridgable() external view returns(bool);

    /**
     * @dev This function is called by users to get new token corresponding to the old one.
     * @param origin Consists of:
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     * - fromBridge: Address of the contract that carries out the first part of the bridging process.
     * @param tokenOwner The owner of the old token.
     * @param oldTokenInfo Consists of:
     * - tokenId: The ID of the old token.
     * - tokenUri: The URI of the old token.
     * @param commitment The validator's commitment.
     * @param secret The validator's revealed value.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * For message format, see "ValidatorSignature" library in "Signature.sol" contract.
     */
    function acquire(
        Origin calldata origin,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment, bytes calldata secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) external;
}
