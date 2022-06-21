//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ToNFT is ERC721, Ownable {
    constructor() ERC721("ToNFT", "TO") {}

    address public toBridge;

    function setToBridge(address toBridge_) public onlyOwner {
        toBridge = toBridge_;
    }

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == toBridge, "Not allowed");
        _safeMint(to, tokenId);
    }
}
