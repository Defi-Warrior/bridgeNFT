//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../AbstractStaticFromBridge.sol";

import "./interfaces/IWarrior.sol";
import "./interfaces/IBodyPart.sol";

contract DefiWarriorFromBridge is AbstractStaticFromBridge {

    /**
     * Address (Ethereum format) of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    address public fromBodyPart;

    /**
     * @dev Constructor
     */
    constructor(address validator_, address fromToken_, address fromBodyPart_)
            AbstractStaticFromBridge(validator_, fromToken_) {
        fromBodyPart = fromBodyPart_;
    }

    /**
     * @dev See AbstractFromBridge.
     * @return 
     */
    function _getTokenUri(address fromToken, uint256 tokenId) internal view virtual override returns (bytes memory) {
        uint32[6] memory partIds = IWarrior(fromToken).getPartIds(tokenId);
        uint32[20][6] memory bodyPartAttributes;

        for(uint256 i = 0; i < 6; i++){
            bodyPartAttributes[i] = IBodyPart(fromBodyPart).getAttributeAt(partIds[i]);
        }

        bytes memory tokenUri = abi.encodePacked(IWarrior(fromToken).getAttributeAt(tokenId), bodyPartAttributes);
        return tokenUri;
    }

    /**
     * @dev 
     */
    function _processToken(
        address fromToken,
        address fromBridge,
        address tokenOwner,
        uint256 tokenId
    ) internal virtual override {
        IERC721(fromToken).transferFrom(tokenOwner, fromBridge, tokenId);
    }
}
