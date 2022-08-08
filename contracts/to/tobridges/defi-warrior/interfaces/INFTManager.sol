//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTManager {
    function mint(
        address to,
        uint32[30] memory warriorAttributes,
        uint32[20][6] memory bodypartAttributes
    ) external returns(uint256);
}
