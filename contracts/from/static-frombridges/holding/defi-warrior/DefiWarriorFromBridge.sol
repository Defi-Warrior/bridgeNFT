//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../../StaticHoldingFromBridge.sol";

import "./interfaces/IWarrior.sol";
import "./interfaces/IBodyPart.sol";

contract DefiWarriorFromBridge is StaticHoldingFromBridge {

    /**
     * Address (Ethereum format) of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    address public fromBodyPart;

    /**
     * @dev Constructor
     */
    constructor(address validator_, address fromToken, address fromBodyPart_) StaticHoldingFromBridge(validator_, fromToken) {
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

        bytes memory tokenUri = abi.encode(IWarrior(fromToken).getAttributeAt(tokenId), bodyPartAttributes);
        return tokenUri;
    }
}
