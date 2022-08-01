//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./interfaces/IFromBridge.sol";
import "../utils/Signature.sol";

/**
 * @title AbstractFromBridge
 * @dev This contract carries out the first part of the process of bridging (converting)
 * user's ERC721 NFTs from this chain to another chain. Both chains are Ethereum-based.
 * The first part is essentially committing (by validator) and processing NFTs.
 * The processing action is either permanent burning or holding custody of the token,
 * depending on implementation.
 */
abstract contract AbstractFromBridge is IFromBridge, Ownable {     

    /**
     * Address (Ethereum format) of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    address public validator;

    /**
     * Mapping from owner's address -> nonce.
     * This nonce is used to prevent replay attack on the owner's request,
     * and also the counter of total bridge requests the owner has made.
     */
    mapping(address => uint256) internal _requestNonces;

    modifier onlyValidator(string memory errorMessage) {
        require(msg.sender == validator, errorMessage);
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(address validator_) {
        validator = validator_;
    }

    /**
     * @dev "validator" setter
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev See IFromBridge.
     */
    function getRequestNonce() external view override returns (uint256) {
        return _requestNonces[msg.sender];
    }

    /**
     * @dev See IFromBridge.
     */
    function getRequestNonce(address tokenOwner) external view override
            onlyValidator("GetRequestNonce: Only validator is allowed to get nonce of arbitrary owner") returns (uint256) {
        return _requestNonces[tokenOwner];
    }

    /**
     * @dev See IFromBridge.
     * @return ERC721 tokenURI by default. Child contracts MAY override to implement
     * the URI management scheme of the tokens they served.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual override returns (bytes memory) {
        return abi.encodePacked(IERC721Metadata(fromToken).tokenURI(tokenId));
    }

    /**
     * @dev See IFromBridge
     */
    function commit(
        address fromToken,
        address toToken, address toBridge,
        address tokenOwner, uint256 requestNonce,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) external virtual override onlyValidator("Commit: Only validator is allowed to commit") {
        address fromBridge = address(this);
        
        // Retrieve token URI.
        bytes memory tokenUri = getTokenUri(fromToken, tokenId);

        // Check all requirements to commit.
        _checkCommitRequirements(
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, requestNonce,
            tokenId, tokenUri,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);

        // Process the token.
        _processToken(fromToken, tokenId);

        // Update nonce.
        _updateNonce(tokenOwner);

        // Emit all events needed.
        _emitEvents(
            fromToken, fromBridge,
            toToken, toBridge,
            tokenOwner, requestNonce,
            tokenId, tokenUri,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature);
    }

    /**
     * @dev Check all requirements of the commit process. If an child contract has more
     * requirements, when overriding, it SHOULD first call super._checkCommitRequirements(...)
     * then add its own requirements.
     * Parameters are virtually the same as "commit" function.
     *
     * Currently the checks are:
     * - Owner's signature.
     * - Validator's signature.
     * - "tokenId"'s owner is "tokenOwner".
     * - FromBridge is approved on "tokenId".
     * - Request's nonce.
     * - The request timestamp determined by the validator is in the past.
     */
    function _checkCommitRequirements(
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner, uint256 requestNonce,
        uint256 tokenId, bytes memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal view virtual {
        // Verify owner's signature.
        require(
            OwnerSignature.verify(
                tokenOwner,
                fromToken, fromBridge,
                toToken, toBridge,
                requestNonce, tokenId,
                authnChallenge,
                ownerSignature),
            "Commit: Invalid owner signature");

        // Verify validator's signature.
        require(
            ValidatorSignature.verify(
                validator,
                fromToken, fromBridge,
                toToken, toBridge,
                tokenOwner, tokenId,
                tokenUri,
                commitment, requestTimestamp,
                validatorSignature),
            "Commit: Invalid validator signature");

        // Check ownership.
        require(IERC721(fromToken).ownerOf(tokenId) == tokenOwner,
            "Commit: The token's owner is incorrect");

        // Check approval.
        require(IERC721(fromToken).isApprovedForAll(tokenOwner, fromBridge) ||
            IERC721(fromToken).getApproved(tokenId) == fromBridge,
            "Commit: FromBridge is not approved on token ID");

        // Check nonce.
        require(_isValidNonce(tokenOwner, requestNonce), "Commit: Invalid nonce");

        // Check request timestamp's validity (i.e. occured in the past).
        require(block.timestamp > requestTimestamp,
            "Commit: Request timestamp must be in the past");
    }

    /**
     * @dev Process the token by burning it. Child contracts could perform different actions
     * by overriding this function. For example, if the bridging process allows the owner to
     * get the token back, the processing action will be transfer the token to FromBridge.
     */
    function _processToken(address fromToken, uint256 tokenId) internal virtual {
        ERC721Burnable(address(fromToken)).burn(tokenId);
    }

    /**
     * @dev Validate request's nonce. Only check equality.
     */
    function _isValidNonce(address tokenOwner, uint256 requestNonce)
    internal virtual view returns (bool) {
        return _requestNonces[tokenOwner] == requestNonce;
    }

    /**
     * @dev Update nonce. Only increase by 1.
     */
    function _updateNonce(address tokenOwner) internal virtual {
        _requestNonces[tokenOwner]++;
    }

    /**
     * @dev Emit all the events needed. Child contracts MAY override to emit the events they want.
     * However, super._emitEvents() SHOULD be called to keep emitting the events of parent contracts.
     * Parameters are the same as "_checkCommitRequirements" function. All values are put in parameter
     * to cover all possible events.
     */
    function _emitEvents(
        address fromToken, address fromBridge,
        address toToken, address toBridge,
        address tokenOwner, uint256 requestNonce,
        uint256 tokenId, bytes memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual;
}
