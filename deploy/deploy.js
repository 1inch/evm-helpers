const { getChainId } = require('hardhat');
const { deployAndGetContract } = require('@1inch/solidity-utils');

const constants = require('./constants');

module.exports = async ({ deployments, getNamedAccounts, config }) => {
    console.log('running deploy script');

    const chainId = await getChainId();
    console.log('network id ', chainId);
    console.log('deployOpts', config.deployOpts);
    
    const CONTRACT_HELPER_NAME = config.deployOpts?.contractHelperName;

    const { deployer } = await getNamedAccounts();
    await deployAndGetContract({
        contractName: CONTRACT_HELPER_NAME,
        deployments,
        deployer,
        constructorArgs: constants.CONSTRUCTOR_ARGS?.[CONTRACT_HELPER_NAME]?.[chainId] ?? [],
    });
};

module.exports.skip = async () => true;
