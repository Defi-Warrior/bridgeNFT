//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Commitment
 * @dev This library is a simple "commitment scheme" that only uses hashing.
 *
 * WARNING: This is not a fully-qualified commitment scheme (by definition)
 * because there is no randomization in it. However the usage is justified
 * because we do not need computation hiding, just a one-way function is sufficient,
 * and we still have computational binding. Therefore a collision-resistant
 * hash function is all we need.
 */
library Commitment {

    /**
     * @dev Verify validator's revealed value to see if it matches the commitment.
     * @param commitment The validator's commitment. This is a hash digest so the data type is bytes32.
     * @param value The validator's revealed value.
     * @return true if the commitment and the value match,
     * i.e. the commitment is the keccak256 digest of the value.
     */
    function verify(
        bytes32 commitment,
        bytes calldata value
    ) internal pure returns (bool) {
        return keccak256(value) == commitment;
    }
}