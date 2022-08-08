//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFromBridgeEvents {
    event Commit(
        address         fromToken,
        uint256         toChainId,
        address         toToken,
        address         toBridge,
        address indexed tokenOwner,
        uint256 indexed requestNonce,
        uint256         tokenId,
        bytes32 indexed commitment,
        uint256         requestTimestamp);
}
