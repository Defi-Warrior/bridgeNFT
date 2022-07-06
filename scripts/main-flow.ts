import { ethers } from "hardhat";

import { FromNFT } from "../typechain-types/contracts/FromNFT"
import { FromNFT__factory } from "../typechain-types/factories/contracts/FromNFT__factory";
import { FromBridge } from "../typechain-types/contracts/FromBridge"
import { FromBridge__factory } from "../typechain-types/factories/contracts/FromBridge__factory";
import { ToNFT } from "../typechain-types/contracts/ToNFT"
import { ToNFT__factory } from "../typechain-types/factories/contracts/ToNFT__factory";
import { ToBridge } from "../typechain-types/contracts/ToBridge"
import { ToBridge__factory } from "../typechain-types/factories/contracts/ToBridge__factory";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import Config from "./config.develop";

async function main() {
    const { deployer, fromNFT, fromBridge, toNFT, toBridge } = await deploy();

    await initialize(deployer, fromNFT, fromBridge, toNFT, toBridge);


}

async function deploy():
        Promise<{   deployer: SignerWithAddress,
                    fromNFT: FromNFT,
                    fromBridge: FromBridge,
                    toNFT: ToNFT,
                    toBridge: ToBridge }> {

    const deployer = (await ethers.getSigners())[0];

    const fromNFT_factory: FromNFT__factory = await ethers.getContractFactory("FromNFT", deployer);
    const fromNFT: FromNFT = await fromNFT_factory.deploy();
    await fromNFT.deployed();

    const fromBridge_factory: FromBridge__factory = await ethers.getContractFactory("FromBridge", deployer);
    const fromBridge: FromBridge = await fromBridge_factory.deploy();
    await fromBridge.deployed();

    const toNFT_factory: ToNFT__factory = await ethers.getContractFactory("ToNFT", deployer);
    const toNFT: ToNFT = await toNFT_factory.deploy();
    await toNFT.deployed();

    const toBridge_factory: ToBridge__factory = await ethers.getContractFactory("ToBridge", deployer);
    const toBridge: ToBridge = await toBridge_factory.deploy();
    await toBridge.deployed();

    return {
        deployer: deployer,
        fromNFT: fromNFT,
        fromBridge: fromBridge,
        toNFT: toNFT,
        toBridge: toBridge
    };
}

async function initialize(
    contractOwner: SignerWithAddress,
    fromNFT: FromNFT,
    fromBridge: FromBridge,
    toNFT: ToNFT,
    toBridge: ToBridge,
) {
    fromBridge.connect(contractOwner);
    fromBridge.initialize(
        fromNFT.address,
        toNFT.address,
        toBridge.address,
        Config.VALIDATOR_ADDRESS
    );

    toNFT.connect(contractOwner);
    toNFT.setToBridge(toBridge.address);

    toBridge.connect(contractOwner);
    toBridge.initialize(
        fromNFT.address,
        fromBridge.address,
        toNFT.address,
        Config.VALIDATOR_ADDRESS,
        Config.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED
    );
}

main();
