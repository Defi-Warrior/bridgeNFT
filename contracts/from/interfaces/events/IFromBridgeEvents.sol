//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IFromBridgeEvents {
    event Commit(
        address indexed fromToken,
        address         toToken,
        address         toBridge,
        address indexed tokenOwner,
        uint256 indexed requestNonce,
        uint256         tokenId,
        bytes32         commitment,
        uint256         requestTimestamp,
        bytes           validatorSignature);
}
