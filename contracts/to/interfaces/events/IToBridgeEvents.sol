//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IToBridgeEvents {
    event Acquire(
        uint256         fromChainId,
        address         fromToken,
        address         fromBridge,
        address indexed acquirer,
        uint256 indexed newTokenId,
        bytes32 indexed commitment,
        uint256         acquirementTimestamp);
}
