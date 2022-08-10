import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import deployAll from "../function/_deploy-all";

const fromNetwork:  NetworkInfo = NETWORK.LOCALHOST_8545;
const toNetwork:    NetworkInfo = NETWORK.LOCALHOST_8546;

deployAll(fromNetwork, toNetwork);
