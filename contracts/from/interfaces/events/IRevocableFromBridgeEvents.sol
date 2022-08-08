//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRevocableFromBridgeEvents {
    event Revoke(
        address indexed revokedValidator,
        address indexed newValidator,
        address indexed revoker);

    event UpdateValidatorSignature(
        address indexed tokenOwner,
        uint256 indexed requestNonce,
        address indexed oldValidator,
        bytes           oldSignature,
        address         newValidator,
        bytes           newSignature);
}
