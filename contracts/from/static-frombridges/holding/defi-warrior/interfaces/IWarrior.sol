//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWarrior is IERC721 {
    function getAttributeAt(uint256 index) external view returns(uint32[30] memory);
    function getPartIds(uint256 tokenId) external view returns(uint32[6] memory);
}
