//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWarrior is IERC721 {
    function getAttributeAt(uint256 index) external view returns(uint32[30] memory);
    function getPartIds(uint tokenId) external view returns(uint32[6] memory);
}
