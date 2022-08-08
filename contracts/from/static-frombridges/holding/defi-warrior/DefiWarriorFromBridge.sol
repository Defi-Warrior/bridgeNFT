//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../StaticHoldingRevocableFromBridge.sol";

import "./interfaces/IWarrior.sol";
import "./interfaces/IBodyPart.sol";

import "../../../../utils/defi-warrior/WarriorEncoding.sol";

/**
 * @title DefiWarriorFromBridge
 * @dev The version of FromBridge that supports only Defi Warrior NFT.
 * When bridging a warrior, the body parts (also ERC721 token) are also bridged.
 */
contract DefiWarriorFromBridge is StaticHoldingRevocableFromBridge {
    using Address for address;

    /**
     * Address (Ethereum format) of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    address private immutable _fromBodyPart;

    /**
     * @dev Constructor.
     */
    constructor(address validator, address fromToken, address fromBodyPart) StaticHoldingRevocableFromBridge(validator, fromToken) {
        require(fromBodyPart.isContract(), "DefiWarriorFromBridge.constructor: FromBodyPart must be a contract");

        _fromBodyPart = fromBodyPart;
    }

    /**
     * @dev "_fromBodyPart" getter.
     */
    function getFromBodyPart() public view returns(address) {
        return _fromBodyPart;
    }

    /**
     * @dev See AbstractFromBridge.
     * @return A special token URI, which is the encode of the warrior's attributes and
     * all the body parts' attributes. DefiWarriorToBridge needs all these data to mint
     * the same warrior.
     */
    function _getTokenUri(address fromToken, uint256 tokenId) internal view override returns(bytes memory) {
        // Get warrior's attributes.
        uint32[30] memory warriorAttributes = IWarrior(fromToken).getAttributeAt(tokenId);

        // Get body parts' attributes.
        uint32[6] memory partIds = IWarrior(fromToken).getPartIds(tokenId);
        uint32[20][6] memory bodypartAttributes;
        for (uint256 i = 0; i < 6; i++){
            bodypartAttributes[i] = IBodyPart(_fromBodyPart).getAttributeAt(partIds[i]);
        }

        // Encode to token URI as bytes.
        bytes memory tokenUri = WarriorEncoding.encode(warriorAttributes, bodypartAttributes);
        
        return tokenUri;
    }
}
