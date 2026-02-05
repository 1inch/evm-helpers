const hre = require('hardhat');
const { getChainId } = hre;
const constants = require('../config/constants');
const { deployAndGetContract } = require('@1inch/solidity-utils');

module.exports = async ({ getNamedAccounts, deployments }) => {
    const networkName = hre.network.name;
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    if (
        networkName in hre.config.networks &&
        chainId !== hre.config.networks[networkName].chainId?.toString()
    ) {
        console.log(`network chain id: ${hre.config.networks[networkName].chainId}, your chain id ${chainId}`);
        console.log('skipping wrong chain id deployment');
        return;
    }

    const { deployer } = await getNamedAccounts();

    const feeCollector = await deployAndGetContract({
        contractName: 'FeeCollector',
        deployments,
        deployer,
        constructorArgs: [constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId]],
    });

    await deployAndGetContract({
        contractName: 'FeeCollectorFactory',
        deployments,
        deployer,
        constructorArgs: [await feeCollector.getAddress(), constants.FEE_COLLECTOR_FACTORY_OWNER[chainId]],
    });
};

module.exports.skip = async () => true;
