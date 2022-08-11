//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IToTokenMinter.sol";
import "./interfaces/IValidatorRevocationAnnouncementReceiver.sol";

contract ToNFT is ERC721URIStorage, IToTokenMinter, IValidatorRevocationAnnouncementReceiver, Ownable {
    constructor() ERC721("ToNFT", "TO") {}

    address public toBridge;
    bool public allowMint = false;

    function setToBridge(address toBridge_) public onlyOwner {
        toBridge = toBridge_;
    }

    function setAllowMint(bool allowMint_) public onlyOwner {
        allowMint = allowMint_;
    }

    function mint(address to, string memory tokenUri) public returns(uint256) {
        require(msg.sender == toBridge, "toBridge: Not allowed to mint");
        require(allowMint, "allowMint: Not allowed to mint");

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

    function isCurrentlyMintable() external override view returns(bool) {
        return allowMint;
    }

    function receiveAnnouncement(address revokedValidator, address newValidator, address revoker) external override {
        require(msg.sender == toBridge, "receiveAnnouncement: Not from toBridge");
        allowMint = false;
    }
}
