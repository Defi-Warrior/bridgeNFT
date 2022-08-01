//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDynamicFromBridgeEvents {
    event Commit(
        address indexed fromToken,
        
        address         toToken,
        address         toBridge,
        address indexed tokenOwner,
        uint256 indexed requestNonce,
        uint256         tokenId,
        bytes           tokenUri,
        bytes32         commitment,
        uint256         requestTimestamp,
        bytes           validatorSignature);
}
