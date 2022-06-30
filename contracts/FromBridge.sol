//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./utils/Signature.sol";

/**
 * @title FromBridge
 * @dev This contract carries out the first part of the process of bridging (converting)
 * user's ERC721 NFTs from this chain to another chain. Both chains are Ethereum-based.
 * The first part is essentially committing (by validator) and burning NFTs.
 */
contract FromBridge is Ownable, Initializable {     

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     *
     * - fromBridge: Address of this contract.
     * fromToken contract and fromBridge contract must be on the same chain.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of the contract that carries out the second part of the bridging process.
     * toToken contract and toBridge contract must be on the same chain.
     *
     * - validator: (Blockchain) Address of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    ERC721Burnable  public fromToken;
    address         public fromBridge;
    address         public toToken;
    address         public toBridge;
    address         public validator;

    event Commit(
        address indexed tokenOwner,
        uint256 indexed tokenId,
        bytes32         commitment,
        uint256         requestTimestamp,
        bytes           validatorSignature);

    modifier onlyValidator(string memory errorMessage) {
        require(msg.sender == validator, errorMessage);
        _;
    }

    constructor() {}

    function initialize(
        address fromToken_,
        address toToken_,
        address toBridge_
    ) external initializer {
        fromToken = ERC721Burnable(fromToken_);
        toToken = toToken_;
        toBridge = toBridge_;

        fromBridge = address(this);
        validator = msg.sender;
    }

    /**
     * @dev Change validator
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev This function is called only by the validator to submit the commitment
     * and burn token at the same time. The token will be burned if this transaction
     * is successfully executed.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param ownerSignature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * For message format, see "verifyOwnerSignature" function in "Signature.sol" contract.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and ToBridge is approved on this token.
     * The owner will use this signature at FromBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function commitAndBurn(
        address tokenOwner,
        uint256 tokenId,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory ownerSignature,
        bytes memory validatorSignature
    ) external onlyValidator("Only validator is allowed to commit") {
        // Verify owner's signature
        require(
            _verifyOwnerSignature(
                tokenOwner, tokenId,
                ownerSignature),
            "Invalid owner signature");

        // Verify validator's signature
        require(
            _verifyValidatorSignature(
                tokenOwner, tokenId,
                commitment, requestTimestamp,
                validatorSignature),
            "Invalid validator signature");

        // Check ownership's correctness
        require(fromToken.ownerOf(tokenId) == tokenOwner, "The token's owner is incorrect");

        // Permanently burn the token
        fromToken.burn(tokenId);

        // Emit event for owner (frontend) to retrieve commitment, timestamp and signature
        emit Commit(tokenOwner, tokenId, commitment, requestTimestamp, validatorSignature);
    }

    /**
     * @dev Wrapper of "verifyOwnerSignature" function in "Signature.sol" contract,
     * for code readability purpose in "commitAndBurn" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param signature The signature signed by the token's owner.
     * For message format, see "verifyOwnerSignature" function in "Signature.sol" contract.
     */
    function _verifyOwnerSignature(
        address tokenOwner, uint256 tokenId,
        bytes memory signature
    ) internal view returns (bool) {
        return Signature.verifyOwnerSignature(
            address(fromToken), fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            signature);
    }

    /**
     * @dev Wrapper of "verifyValidatorSignature" function in "Signature.sol" contract,
     * for code readability purpose in "commitAndBurn" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param signature The signature signed by the validator.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function _verifyValidatorSignature(
        address tokenOwner, uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        // Retrieve tokenURI to gather all necessary materials to craft signed message.
        string memory tokenUri = fromToken.tokenURI(tokenId);

        return Signature.verifyValidatorSignature(
            address(fromToken), fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            validator,
            signature);
    }
}
