//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IClaimToBridgeEvents {
    event Claim(
        uint256         fromChainId,
        address         fromToken,
        address         fromBridge,
        bytes32 indexed commitment,
        uint256         claimTimestamp);

    event AcquireByClaim(
        address indexed acquirer,
        uint256 indexed newTokenId,
        bytes32 indexed commitment,
        uint256         acquirementTimestamp);

    event Deny(
        bytes32 indexed commitment,
        uint256         denialTimestamp);
}
