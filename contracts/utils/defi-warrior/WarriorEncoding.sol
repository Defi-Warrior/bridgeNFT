//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library WarriorEncoding {
    function encode(
        uint32[30] memory warriorAttributes,
        uint32[20][6] memory bodyPartAttributes)
    internal pure returns(bytes memory) {
        return abi.encode(warriorAttributes, bodyPartAttributes);
    }

    function decode(bytes memory tokenUri) internal pure returns(
            uint32[30] memory warriorAttributes,
            uint32[20][6] memory bodyPartAttributes) {
        (warriorAttributes, bodyPartAttributes) = abi.decode(tokenUri, (uint32[30], uint32[20][6]));
    }
}
