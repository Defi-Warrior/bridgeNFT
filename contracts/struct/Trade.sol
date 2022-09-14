//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DTO {
    struct Trade {
        bytes32 tradeId;
        address alice;
        address bob;
        uint256 formerTradeChainId;
        address formerTradeOperator;
        HalfTradeData formerTradeData;
        uint256 latterTradeChainId;
        address latterTradeOperator;
        HalfTradeData latterTradeData;
        TimeConstraint timeConstraint;
        uint256 maxAssetLockFee;
        SignatureData aliceSignatureData;
        SignatureData bobSignatureData;
        SignatureData validatorSignatureData;
        uint256 proofVerifierId;
        bytes statementThatTradeAtFormerTradeIsFinished;
        bytes proofOfStatement;
        uint256 tradeNonce;
        bytes databaseInstruction; // what to emit? what to store? emit token data?
    }

    struct HalfTradeData {
        Process[] assetsAliceOffer;
        Process[] feeOnAlice;
        Process[] assetsBobOffer;
        Process[] feeOnBob;
    }

    struct Process {
        Asset asset;
        string action; // "TRANSFER" / "BURN" / "MINT" (not use enum for further extensions)
        address receiver;
    }

    struct Asset {
        string  assetType; // "NATIVE" / "ERC20" / "ERC777" / "ERC721" / "ERC1155" (not use enum for further extensions)
        address tokenAddress;
        uint256 amount;
        uint256 tokenId;
        bytes   tokenData; // URI
        bytes   data; // data for minter / ERC receiver
    }
    
    struct TimeConstraint {
        uint256 bothHalfTradesNotValidBefore;
        uint256 formerTradeNotValidAfter;
        uint256 latterTradeNotValidAfter;
    }

    struct SignatureData {
        uint256 tradeHasherId;
        uint256 signatureVerifierId;
        bytes signature;
    }
}
