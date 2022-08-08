//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IStaticFromBridge.sol";
import "./AbstractFromBridge.sol";

/**
 * @title AbstractStaticFromBridge
 * @dev The version of FromBridge that works with only one specific FromToken due to
 * the non-standard URI of that token. Hence "static" in the name.
 */
abstract contract AbstractStaticFromBridge is IStaticFromBridge, AbstractFromBridge {
    using Address for address;

    /**
     * Address (Ethereum format) of the token this FromBridge serves.
     */
    address private immutable _fromToken;

    /* ********************************************************************************************** */

    modifier validateFromToken(address fromToken, string memory errorMessage) {
        require(fromToken == _fromToken, errorMessage);
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(address fromToken) {
        // Check all FromToken requirements.
        _checkFromTokenRequirements(fromToken);

        _fromToken = fromToken;
    }

    /**
     * @dev Check all "fromToken" requirements.
     *
     * Currently the checks are:
     * - fromToken is a contract.
     */
    function _checkFromTokenRequirements(address fromToken) internal view virtual {
        require(fromToken.isContract(), "AbstractStaticFromBridge.constructor: FromToken must be a contract");
    }

    /**
     * @dev "_fromToken" getter.
     */
    function getFromToken() public view override returns(address) {
        return _fromToken;
    }

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.getTokenUri" to add fromToken validation.
     * @return result of "super.getTokenUri" function.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual override(IFromBridge, AbstractFromBridge)
            validateFromToken(fromToken, "getTokenUri: Only the token supported by this FromBridge is allowed to be called on")
            returns(bytes memory) {
        // Will call "AbstractFromBridge.getTokenUri" function.
        return super.getTokenUri(fromToken, tokenId);
    }

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.commit" to add fromToken validation.
     */
    function commit(
        address fromToken,
        Destination calldata destination,
        RequestId calldata requestId,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) public virtual override(IFromBridge, AbstractFromBridge)
    validateFromToken(fromToken, "commit: Only the token supported by this FromBridge is allowed to be called on") {
        // Will call "AbstractFromBridge.commit" function.
        super.commit(
            fromToken,
            destination,
            requestId,
            tokenId,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature
        );
    }
}
