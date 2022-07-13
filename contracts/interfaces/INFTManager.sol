//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTManager {
    function mint(address, uint32[30] memory, uint32[20][6] memory) external returns(uint256);
}