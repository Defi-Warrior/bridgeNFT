import DeployConfig from "./types/config/deploy-config";
import ValidatorConfig from "./types/config/validator-config";
import OwnerConfig from "./types/config/owner-config";

export const deployConfig: DeployConfig = {
    "ADDRESS_VALIDATOR": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",

    "GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED": 10
};

export const validatorConfig: ValidatorConfig = {
    "NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION": 0
};

export const ownerConfig: OwnerConfig = {
    "NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION": 0
};
