//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Nft1.sol";

contract FromBridge is IERC721Receiver, Ownable {
    enum nftStatus { LOCKED, BURNED, RETURNED }

    struct RequestDetail {
        uint256 nftId;
        uint256 timestamp;
        nftStatus status;
    }

    mapping(address => mapping(uint256 => RequestDetail)) 	private _requestList;
    mapping(address => uint256) 							private _requestCountPerUser;
    
    Nft1    public token;
    uint256 public lockNftDuration;

    event Request(address indexed owner,
        uint256 indexed requestId,
        uint256 indexed nftId,
        uint256 timestamp);

    constructor(address tokenAddr_, uint256 lockNftDuration_) {
        token = Nft1(tokenAddr_);
        lockNftDuration = lockNftDuration_;
    }

    function request(uint256 nftId) public {
        require(token.ownerOf(nftId) == msg.sender, "NFT is not owned by message sender");
        address nftOwner = msg.sender;

        // Get requestId for this request
        uint256 requestId = _requestCountPerUser[nftOwner];

        // Transfer NFT to bridge
        token.safeTransferFrom(nftOwner, address(this), nftId);

        // Save request
        requestTimestamp = block.timestamp;
        _requestList[nftOwner][requestId] = RequestDetail(nftId, requestTimestamp, nftStatus.LOCKED);

        // Emit event
        emit Request(nftOwner, requestId, nftId, requestTimestamp);
    }

    function claimBack(uint256 requestId) public {
        
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721.onERC721Received.selector;
    }
}
