//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nft1 is ERC721Burnable, Ownable {
    constructor() ERC721("NFT1", "N1") {}
}
