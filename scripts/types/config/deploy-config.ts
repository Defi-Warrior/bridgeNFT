import { BigNumber } from "ethers";

type DeployConfig = {    
    readonly GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED: BigNumber,
    readonly GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM: BigNumber,
    readonly MINIMUM_ESCROW: BigNumber
};

export default DeployConfig;
