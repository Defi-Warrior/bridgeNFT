import { BigNumber } from "ethers";

import DeployConfig from "../../scripts/types/config/deploy-config";
import ValidatorConfig from "../../scripts/types/config/validator-config";
import OwnerConfig from "../../scripts/types/config/owner-config";

export const deployConfig: DeployConfig = {
    GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED: BigNumber.from(10),
    GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM: BigNumber.from(259200),    // 3 days = 259200 seconds
    MINIMUM_ESCROW: BigNumber.from(0)   // estimate later
};

const NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: number = 6;

export const validatorConfig: ValidatorConfig = {
    NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION
};

export const ownerConfig: OwnerConfig = {
    NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION: NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION
};
