import DeployConfig from "../types/config/deploy-config"
import OwnerConfig from "../types/config/owner-config"
import ValidatorConfig from "../types/config/validator-config"
import ENV from "../../env"

const config = require("../../env/" + ENV + "/config");

export const deployConfig:      DeployConfig    = config.deployConfig;
export const ownerConfig:       OwnerConfig     = config.ownerConfig;
export const validatorConfig:   ValidatorConfig = config.validatorConfig;
