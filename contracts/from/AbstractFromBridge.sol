//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

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
            onlyValidator("getRequestNonce: Only validator is allowed to get nonce of arbitrary owner") returns (uint256) {
        return _requestNonces[tokenOwner];
    }

    /**
     * @dev See IFromBridge.
     * Child contracts MAY override to add further validation if needed.
     * @return result of "_getTokenUri" function.
     */
    function getTokenUri(address fromToken, uint256 tokenId) public view virtual override returns (bytes memory) {
        return _getTokenUri(fromToken, tokenId);
    }

    /**
     * @dev The internal function of "getTokenUri" function.
     * @return ERC721 tokenURI by default. Child contracts MAY override to implement
     * the URI management scheme of the tokens they served.
     */
    function _getTokenUri(address fromToken, uint256 tokenId) internal view virtual returns (bytes memory) {
        return abi.encodePacked(IERC721Metadata(fromToken).tokenURI(tokenId));
    }

    /**
     * @dev See IFromBridge
     */
    function commit(
        address fromToken,
        Destination calldata destination,
        RequestId calldata requestId,
        uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) public virtual override onlyValidator("commit: Only validator is allowed to commit") {

        Origin memory origin = Origin(fromToken, address(this));
        TokenInfo memory tokenInfo = TokenInfo(tokenId, _getTokenUri(fromToken, tokenId));

        // Check all requirements to commit.
        _checkCommitRequirements(
            origin,
            destination,
            requestId,
            tokenInfo,
            commitment, requestTimestamp,
            authnChallenge,
            ownerSignature, validatorSignature
        );

        // Process the token.
        _processToken(origin, requestId.tokenOwner, tokenId);

        // Update nonce.
        _updateNonce(requestId.tokenOwner);

        // Emit all events needed.
        _emitEvents(
            origin,
            destination,
            requestId,
            tokenInfo,
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
        Origin memory origin,
        Destination calldata destination,
        RequestId calldata requestId,
        TokenInfo memory tokenInfo,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal view virtual {
        // Verify owner's signature.
        require(
            OwnerSignature.verify(
                requestId.tokenOwner,
                origin.fromToken, origin.fromBridge,
                destination.toToken, destination.toBridge,
                requestId.requestNonce, tokenInfo.tokenId,
                authnChallenge,
                ownerSignature),
            "commit: Invalid owner signature");

        // Verify validator's signature.
        require(
            ValidatorSignature.verify(
                validator,
                origin.fromToken, origin.fromBridge,
                destination.toToken, destination.toBridge,
                requestId.tokenOwner, tokenInfo.tokenId,
                tokenInfo.tokenUri,
                commitment, requestTimestamp,
                validatorSignature),
            "commit: Invalid validator signature");

        // Check ownership.
        require(IERC721(origin.fromToken).ownerOf(tokenInfo.tokenId) == requestId.tokenOwner,
            "commit: The token's owner is incorrect");

        // Check approval.
        require(IERC721(origin.fromToken).isApprovedForAll(requestId.tokenOwner, origin.fromBridge) ||
            IERC721(origin.fromToken).getApproved(tokenInfo.tokenId) == origin.fromBridge,
            "commit: This FromBridge is not approved on token ID");

        // Check nonce.
        require(_isValidNonce(requestId.tokenOwner, requestId.requestNonce), "commit: Invalid nonce");

        // Check request timestamp's validity (i.e. occured in the past).
        require(block.timestamp > requestTimestamp,
            "commit: Request timestamp must be in the past");
    }

    /**
     * @dev Process the token by either burning or transfering it to the FromBridge,
     * depends on child contracts' implementation.
     */
    function _processToken(Origin memory origin, address tokenOwner, uint256 tokenId) internal virtual;

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
        Origin memory origin,
        Destination calldata destination,
        RequestId calldata requestId,
        TokenInfo memory tokenInfo,
        bytes32 commitment, uint256 requestTimestamp,
        bytes calldata authnChallenge,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal virtual {
        emit Commit(
            origin.fromToken,
            destination.toToken, destination.toBridge,
            requestId.tokenOwner, requestId.requestNonce,
            tokenInfo.tokenId,
            commitment, requestTimestamp,
            validatorSignature);
    }
}