//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../AbstractClaimToBridge.sol";
import "../../AbstractRevocableToBridge.sol";

import "../../_ToNFT.sol";
import "../../interfaces/IToTokenMinter.sol";

/**
 * @title ToNftToBridge
 * @dev ToBridge specialized for ToNFT, supporting claim functionality
 * and validator revocation.
 * See respective parent contracts for further explanations.
 */
contract ToNftToBridge is AbstractClaimToBridge, AbstractRevocableToBridge {
    using Address for address;

    /**
     * @dev Constructor.
     */
    constructor(
        address toToken,
        address validator,
        uint256 globalWaitingDurationForOldTokenToBeProcessed,
        address denier,
        uint256 globalWaitingDurationToAcquireByClaim,
        uint256 minimumEscrow)
            AbstractToBridge(toToken, validator, globalWaitingDurationForOldTokenToBeProcessed)
            AbstractClaimToBridge(denier, globalWaitingDurationToAcquireByClaim, minimumEscrow) {}

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractToBridge.
     */
    function isCurrentlyMintable() public view override(IToBridge, AbstractToBridge) returns(bool) {
        return IToTokenMinter(getToToken()).isCurrentlyMintable();
    }

    /**
     * @dev See AbstractToBridge.
     */
    function _mint(address to, bytes memory tokenUri) internal override returns(uint256) {
        uint256 newTokenId = ToNFT(getToToken()).mint(to, string(tokenUri));

        return newTokenId;
    }

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractRevocableToBridge.
     */
    function _announceRevocationToAll(address revokedValidator, address newValidator, address revoker) internal override {
        _announceRevocationTo(getToToken(), revokedValidator, newValidator, revoker);
    }
}
