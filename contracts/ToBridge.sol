//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./utils/Signature.sol";

/**
 * @title ToBridge
 * @dev This contract carries out the second part of the process of bridging (converting)
 * user's ERC721 NFTs from another chain to this chain. Both chains are Ethereum-based.
 * The second part is essentially minting new NFTs corresponding to the old ones for users.
 */
contract ToBridge is Ownable, Initializable {

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
    ERC721  public toToken;
    address public toBridge;
    address public server;
    uint256 public globalWaitingDurationToAcquire;

    /**
     * Mapping from user address -> token's ID -> list of requests from that user on that token's ID.
     * This mapping stores all request for all users.
     * A request (RequestDetail) is uniquely identified by the combination (user address, token's ID, nonce).
     * The nonce is the RequestDetail[] array's index. Therefore, the nonce of one request can
     * be duplicate with the nonce from another request that differs user address or token's ID.
     */
    mapping(address => mapping(uint256 => AcquirementDetail)) private _acquirements;

    /**
     * 
     */
    mapping(address => mapping(uint256 => uint256)) private _nonces;

    constructor() {}

    function initialize(
        address fromTokenAddr_,
        address fromBridgeAddr_,
        address toTokenAddr_,
        uint256 globalWaitingDurationToAcquire_
    ) external initializer {
        fromToken = fromTokenAddr_;
        fromBridge = fromBridgeAddr_;
        toToken = ERC721(toTokenAddr_);
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

    function acquire(uint256 tokenId, uint256 nonce, uint256 requestTimestamp) external {
        address tokenOwner = msg.sender;

    }
}
