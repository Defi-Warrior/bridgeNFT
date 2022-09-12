//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DTO {
    struct Asset {
        string  assetType; // "Native" / "ERC20" / "ERC777" / "ERC721" / "ERC1155" / "CALL"
        address tokenAddress;
        uint256 amount;
        uint256 tokenId;
        bytes   tokenData; // URI
        uint256 gas;
        bytes   payload;
        bytes   data; // data for minter / ERC receiver
    }

    struct Transfer {
        Asset asset;
        address receiver;
    }

    struct Trade {
        bytes32 tradeId;
        address alice;
        address bob;
        uint256 formerExchangeChainId;
        address formerExchange;
        Transfer[] assetsAliceOfferForTradeAtFormerExchange;
        Transfer[] feeOnAliceAtFormerExchange;
        Transfer[] assetsBobOfferForTradeAtFormerExchange;
        Transfer[] feeOnBobAtFormerExchange;
        uint256 latterExchangeChainId;
        address latterExchange;
        Transfer[] assetsAliceOfferForTradeAtLatterExchange;
        Transfer[] feeOnAliceAtLatterExchange;
        Transfer[] assetsBobOfferForTradeAtLatterExchange;
        Transfer[] feeOnBobAtLatterExchange;
        uint256 bothTradesNotValidBefore;
        uint256 tradeAtFormerExchangeNotValidAfter;
        uint256 tradeAtLatterExchangeNotValidAfter;
        uint256 maxAssetLockFee;
        uint256 tradeHasherId;
        uint256 aliceSignatureVerifierId;
        uint256 bobSignatureVerifierId;
        uint256 validatorSignatureVerifierId;
        uint256 proofVerifierId;
        bytes statementThatTradeAtFormerExchangeIsFinished;
        bytes proofOfStatement;
        uint256 tradeNonce;
    }
}
