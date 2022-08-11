import { BigNumber } from "ethers";

import DeployConfig from "../../scripts/types/config/deploy-config";
import ValidatorConfig from "../../scripts/types/config/validator-config";
import OwnerConfig from "../../scripts/types/config/owner-config";

export const deployConfig: DeployConfig = {
    GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED: BigNumber.from(0),
    GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM: BigNumber.from(0),
    MINIMUM_ESCROW: BigNumber.from(0)
};

const NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: number = 0;

export const validatorConfig: ValidatorConfig = {
    NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION
};

export const ownerConfig: OwnerConfig = {
    NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION
};
