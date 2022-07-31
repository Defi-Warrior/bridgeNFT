import Network from "../../types/network-enum";
import deployAll from "../function/_deploy-all";

const fromNetwork:  Network = Network.LOCALHOST_8545;
const toNetwork:    Network = Network.LOCALHOST_8546;

deployAll(fromNetwork, toNetwork);
