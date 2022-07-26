import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import '@typechain/hardhat'

export default {
    solidity: "0.8.4",
    defaultNetwork: "localhost",
    networks: {
        hardhat: {},
        localhost: {
            url: "http://127.0.0.1:8545"
        },
        bsctest: {
            url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
            accounts: [process.env.PRIVATE_KEY],
        },
        bscmainnet: {
            url: "https://bsc-dataseed.binance.org/",
            accounts: [process.env.PRIVATE_KEY],
        }
    }
};
