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

    function mint(address to, string memory tokenUri) public returns(uint256) {
        require(msg.sender == toBridge, "Not allowed");

        uint256 tokenId = _findAvailableTokenId();

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, tokenUri);

        return tokenId;
    }

    /**
     * @dev Utility function to help find an ID that is currently available (not owned),
     * in order to mint new token.
     * @return An available token ID.
     */
    function _findAvailableTokenId() internal view virtual returns(uint256) {
        uint256 tokenId;
        uint256 i = 0;
        
        while (true) {
            // Generate somewhat hard-to-collide ID.
            tokenId = uint256(keccak256( abi.encodePacked(address(this), block.timestamp, i) ));

            if (!_exists(tokenId)) {
                break;
            }
            i++;
        }
        return tokenId;
    }
}
