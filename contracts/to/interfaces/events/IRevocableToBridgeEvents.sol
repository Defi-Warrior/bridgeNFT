//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRevocableToBridgeEvents {
    event Revoke(
        address indexed revokedValidator,
        address indexed newValidator,
        address indexed revoker,
        uint256         revocationTimestamp);
}
