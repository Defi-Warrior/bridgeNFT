//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FromNFT is ERC721URIStorage, ERC721Burnable, Ownable {
    constructor() ERC721("FromNFT", "FROM") {}

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        // Need test to ensure it will call ERC721URIStorage._burn function.
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        // Need test to ensure it will call ERC721URIStorage.tokenURI function,
        // not ERC721.tokenURI function.
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Need for test. Will delete later.
     */
    function mint(address to, uint256 tokenId, string memory tokenUri) public onlyOwner {
        _safeMint(to, tokenId);

        _setTokenURI(tokenId, tokenUri);
    }
}
