//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ToNFT is ERC721URIStorage, Ownable {
    constructor() ERC721("ToNFT", "TO") {}

    address public toBridge;

    function setToBridge(address toBridge_) public onlyOwner {
        toBridge = toBridge_;
    }

    function mint(address to, uint256 tokenId, string memory tokenUri) public {
        require(msg.sender == toBridge, "Not allowed");

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, tokenUri);
    }
}
