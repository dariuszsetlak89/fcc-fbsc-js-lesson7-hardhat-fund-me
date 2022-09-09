// Standard deploy:
// import
// main function
// calling of main function

// function deployFunc(hre) {
//     console.log("Hi!");
//     // hre.getNamedAccounts();
//     // hre.deployments;
// }
// module.exports.default = deployFunc;

// module.exports = async hre => {
//     const { getNamedAccounts, deployments } = hre;

const { TASK_DEPLOY_RUN_DEPLOY } = require("hardhat-deploy");

// const helperConfig = require("../helper-hardhat-config");
// const networkConfig = helperConfig.networkConfig;
const {
    networkConfig,
    developmentChains
} = require("../helper-hardhat-config");
const { network } = require("hardhat");
const { verify } = require("../utils/verify.js");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId;

    // if chainId is X use address Y
    // if chainId is Z use address A
    // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
    let ethUsdPriceFeedAddress;
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await get("MockV3Aggregator");
        ethUsdPriceFeedAddress = ethUsdAggregator.address;
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
    }

    // if the contract doesn't exist, we deploy a minimal version for our local testing - Mock

    // well what happens whgen we want to change chains?
    // when going for localhost or hardhat network we want to use a mock
    const args = [ethUsdPriceFeedAddress];
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address
        log: TASK_DEPLOY_RUN_DEPLOY,
        waitConfirmations: network.config.blockConfirmations || 1
    });
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args);
    }
    log("--------------------------------------------------------------");
};

module.exports.tags = ["all", "fundme"];
