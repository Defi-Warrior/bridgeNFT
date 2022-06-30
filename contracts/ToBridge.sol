//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./ToNFT.sol";
import "./utils/Signature.sol";

/**
 * @title ToBridge
 * @dev This contract carries out the second part of the process of bridging (converting)
 * user's ERC721 NFTs from another chain to this chain. Both chains are Ethereum-based.
 * The second part is essentially minting new NFTs corresponding to the old ones for users.
 */
contract ToBridge is Ownable, Initializable {

    struct RequestId {
        address tokenOwner;
        uint256 tokenId;
        uint256 nonce;
    }

    struct AcquirementDetail {
        address acquirer;
        uint256 requestTimestamp;
        uint256 waitingDurationToAcquire;
        uint256 timestamp;
    }

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     *
     * - fromBridge: Address of the contract that carries out the first part of the bridging process.
     * fromToken contract and fromBridge contract must be on the same chain.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of this contract.
     * toToken contract and toBridge contract must be on the same chain.
     *
     * - validator: (Blockchain) Address of the validator that confirms request on the other chain
     * and provides user signature to obtain the new token on this chain.
     *
     * - globalWaitingDurationForOldTokenToBeBurned: The duration the token owner needs to wait
     * after requesting bridging token at fromBridge, in order to acquire the new token.
     * - globalWaitingDurationToAcquireByClaim: 
     */
    address public fromToken;
    address public fromBridge;
    ToNFT   public toToken;
    address public toBridge;
    address public validator;
    uint256 public globalWaitingDurationForOldTokenToBeBurned;
    uint256 public globalWaitingDurationToAcquireByClaim;

    /**
     * Mapping from token's ID on OLD chain -> the acquirement on that token's ID.
     * An acquirement will only be stored if a transaction call to "acquire" function succeeds.
     */
    mapping(uint256 => AcquirementDetail) private _acquirements;

    /**
     * Mapping from user address -> token's ID -> the nonce used to acquire token.
     * 
     */
    mapping(address => mapping(uint256 => uint256)) private _latestNonces;

    event Acquire(
        address indexed acquirer,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         requestTimestamp,
        uint256         waitingDurationToAcquire,
        uint256         acquirementTimestamp);

    event Reject(
        address indexed acquirer,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         rejectTimestamp);

    event ForceMint(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         forceMintTimestamp);

    modifier onlyValidator(string memory errorMessage) {
        require(msg.sender == validator, errorMessage);
        _;
    }

    constructor() {}

    function initialize(
        address fromToken_,
        address fromBridge_,
        address toToken_,
        uint256 globalWaitingDurationToAcquire_
    ) external initializer {
        fromToken = fromToken_;
        fromBridge = fromBridge_;
        toToken = ToNFT(toToken_);
        globalWaitingDurationToAcquire = globalWaitingDurationToAcquire_;

        toBridge = address(this);
        validator = msg.sender;
    }

    /**
     * @dev Change validator
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev Change globalWaitingDurationToAcquire
     */
    function setGlobalWaitingDurationToAcquire(uint256 newGlobalWaitingDurationToAcquire) external onlyOwner {
        globalWaitingDurationToAcquire = newGlobalWaitingDurationToAcquire;
    }

    /**
     * @dev User calls this function to get new token corresponding to the old one.
     * @param requestId Consists of token owner's address, token's ID and nonce.
     * @param requestTimestamp The request timestamp stored in FromBridge.
     * @param signature This signature was signed by the validator to confirm the request
     * after seeing the "Request" event emitted from FromBridge.
     */
    function acquire(
        RequestId calldata requestId,
        uint256 requestTimestamp,
        bytes memory signature
    ) external {
        // Verify if the provided information of the request is true
        bytes memory message = abi.encodePacked("ConfirmNftBurned",
            fromToken, fromBridge,
            address(toToken), toBridge,
            requestId.tokenOwner, requestId.tokenId,
            requestId.nonce, requestTimestamp
        );
        require(Signature.verifySignature(validator, message, signature), "Invalid signature");

        // The token must not have been acquired
        require(!_isAcquired(requestId.tokenId), "Token has been acquired");

        // By policy, token owners must acquire by themselves
        require(msg.sender == requestId.tokenOwner, "Token can only be acquired by its owner");

        // Revert if user did not wait enough time
        require(block.timestamp > requestTimestamp + globalWaitingDurationToAcquire, "Elapsed time from request is not enough");

        // Revert if request had been rejected by validator
        require(!_isRejected(requestId), "This request for token acquirement has been rejected by the validator");

        // Save acquirement
        uint256 waitingDurationToAcquire = globalWaitingDurationToAcquire;
        uint256 acquirementTimestamp = block.timestamp;
        _acquirements[requestId.tokenId] = AcquirementDetail(requestId.tokenOwner,
                                                                requestTimestamp,
                                                                waitingDurationToAcquire,
                                                                acquirementTimestamp);

        // Mint a new token corresponding to the old one
        toToken.mint(requestId.tokenOwner, requestId.tokenId);

        // Emit event
        emit Acquire(
            requestId.tokenOwner,
            requestId.tokenId,
            requestId.nonce,
            requestTimestamp,
            waitingDurationToAcquire,
            acquirementTimestamp);
    }

    /**
     * @dev In case the validator noticed that the confirmation transaction sent to fromBridge had not
     * been finalized (i.e not included in some block that is, for example, 6 blocks backward
     * from the newest block) after a specific period of time (e.g 10 minutes), the validator would
     * call this function to reject user to acquire token by using that unconfirmed request.
     * 
     * It should be noted that the request sent to this function must be the latest request
     * corresponding to that token processed by fromBridge. Because technically what this function
     * does is just increasing the latest nonce by 1, thus making the nonces unsynchronized.
     *
     * @param requestId Consists of token owner's address, token's ID and nonce.
     */
    function rejectAcquirementByRequest(RequestId calldata requestId)
            external onlyValidator("Only validator is allowed to reject request") {
        // The token must not have been acquired
        require(!_isAcquired(requestId.tokenId), "Token has been acquired");

        // Make this nonce unsynchronized (i.e. unequal) with the nonce stored in FromBridge,
        // so that user could not acquire token using the nonce in this request.
        // Note that, by increment by 1, this nonce will auto resynchronized with the other after user
        // claims his/her token back at FromBridge.
        _latestNonces[requestId.tokenOwner][requestId.tokenId]++;

        // Emit event
        uint256 rejectTimestamp = block.timestamp;
        emit Reject(requestId.tokenOwner, requestId.tokenId, requestId.nonce, rejectTimestamp);
    }

    /**
     * @dev The validator could reallow acquirement by a request that was previously rejected 
     * @param requestId Consists of token owner's address, token's ID and nonce.
     * @param requestTimestamp The request's timestamp
     */
    function forceMintAfterReject(RequestId calldata requestId, uint256 requestTimestamp)
            external onlyValidator("Only validator is allowed to force mint") {
        // The token must not have been acquired
        require(!_isAcquired(requestId.tokenId), "Token has been acquired");

        // Save acquirement
        // Set "waitingDurationToAcquire" to 0 instead of "globalWaitingDurationToAcquire"
        // to distinguish force minting from normal acquirement.
        uint256 waitingDurationToAcquire = 0;
        uint256 forceMintTimestamp = block.timestamp;
        _acquirements[requestId.tokenId] = AcquirementDetail(requestId.tokenOwner,
                                                                requestTimestamp,
                                                                waitingDurationToAcquire,
                                                                forceMintTimestamp);

        // Resynchronize nonce. The nonce value after subtract acts as the nonce
        // used to acquire
        _latestNonces[requestId.tokenOwner][requestId.tokenId]--;

        // Mint a new token corresponding to the old one
        toToken.mint(requestId.tokenOwner, requestId.tokenId);

        // Emit event
        emit ForceMint(
            requestId.tokenOwner,
            requestId.tokenId,
            requestId.nonce,
            forceMintTimestamp);
    }

    /**
     * @dev The token had been acquired if and only if the "_acquirements" mapping would
     * have stored non-default values in the AcquirementDetail struct. The default value
     * of every storage slot is 0.
     * @param tokenId The token's ID on old chain.
     * @return true if the token has already been acquired.
     */
    function _isAcquired(uint256 tokenId) internal view returns (bool) {
        return _acquirements[tokenId].timestamp != 0;
    }

    /**
     * @dev The request has been rejected by the validator if and only if the nonce coming from the
     * request (which originated from FromBridge) and the nonce stored in "_latestNonces"
     * are unequal.
     * @param requestId Consists of token owner's address, token's ID and nonce.
     * @return true if the request has been rejected by the validator.
     */
    function _isRejected(RequestId calldata requestId) internal view returns (bool) {
        return requestId.nonce != _latestNonces[requestId.tokenOwner][requestId.tokenId];
    }
}
