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
     * - server: (Blockchain) Address of the server that confirms request on the other chain
     * and provides user signature to obtain the new token on this chain.
     *
     * - globalWaitingDurationToAcquire: The duration the token owner needs to wait
     * after requesting bridging token at fromBridge, in order to acquire the new token.
     */
    address public fromToken;
    address public fromBridge;
    ToNFT   public toToken;
    address public toBridge;
    address public server;
    uint256 public globalWaitingDurationToAcquire;

    /**
     * Mapping from user address -> token's ID -> the acquirement from that user on that token's ID.
     * This mapping stores all acquirement for all users.
     * An acquirement (AcquirementDetail) is uniquely identified by the combination (user address, token's ID).
     * An acquirement will only be stored if a transaction call to "acquire" function succeeds.
     */
    mapping(address => mapping(uint256 => AcquirementDetail)) private _acquirements;

    /**
     * Mapping from user address -> token's ID -> the nonce used to acquire token.
     * 
     */
    mapping(address => mapping(uint256 => uint256)) private _latestNonces;

    event Acquire(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         requestTimestamp,
        uint256         waitingDurationToAcquire,
        uint256         acquirementTimestamp);

    modifier onlyServer(string memory errorMessage) {
        require(msg.sender == server, errorMessage);
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
        server = msg.sender;
    }

    /**
     * @dev Change server
     */
    function setServer(address newServer) external onlyOwner {
        server = newServer;
    }

    /**
     * @dev Change globalWaitingDurationToAcquire
     */
    function setGlobalWaitingDurationToAcquire(uint256 newGlobalWaitingDurationToAcquire) external onlyOwner {
        globalWaitingDurationToAcquire = newGlobalWaitingDurationToAcquire;
    }

    /**
     * @dev 
     * @param requestId Consists of token owner's address, token's ID and nonce.
     * @param requestTimestamp The request timestamp stored in FromBridge.
     * @param signature This signature was signed by the server to confirm the request
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
        require(Signature.verifySignature(server, message, signature), "Invalid signature");

        // By policy, token owners must acquire by themselves
        require(msg.sender == requestId.tokenOwner, "Token can only be acquired by its owner");

        // 
        require(requestId.nonce == _latestNonces[requestId.tokenOwner][requestId.tokenId],
            "This request has been disallowed to acquire token by the server");

        // 
        require(block.timestamp > requestTimestamp + globalWaitingDurationToAcquire, "Elapsed time from request is not enough");

        // Mint a new token corresponding to the old one
        toToken.mint(requestId.tokenOwner, requestId.tokenId);

        // Save acquirement
        uint256 waitingDurationToAcquire = globalWaitingDurationToAcquire;
        uint256 acquirementTimestamp = block.timestamp;
        _acquirements[requestId.tokenOwner][requestId.tokenId] =
            AcquirementDetail(requestTimestamp, waitingDurationToAcquire, acquirementTimestamp);

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
     * @dev In case the server noticed that the confirmation transaction sent to fromBridge had not
     * been finalized (i.e not included in some block that is, for example, 6 blocks backward
     * from the newest block) after a specific period of time (e.g 10 minutes), the server would
     * call this function to disallow user to acquire token by using that unconfirmed request.
     * 
     * It should be noted that the request sent to this function must be the latest request
     * corresponding to that token processed by fromBridge. Because technically what this function
     * does is just increasing the latest nonce by 1, thus making the nonces unsynchronized.
     *
     * @param requestId Consists of token owner's address, token's ID and nonce.
     */
    function disallowAcquirementByRequest(RequestId calldata requestId) external onlyServer("") {
        // require tokenId not yet minted
        
    }

    /**
     * @dev The server could reallow acquirement by a request that was previously disallowed 
     * @param requestId Consists of token owner's address, token's ID and nonce.
     */
    function forceMintAfterDisallowment(RequestId calldata requestId) external onlyServer("") {
        // require tokenId not yet minted
    }
}
