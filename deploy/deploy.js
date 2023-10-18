const { getChainId } = require('hardhat');
const { deployAndGetContract } = require('@1inch/solidity-utils');

module.exports = async ({ deployments, getNamedAccounts }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const CONTRACT_HELPER_NAME = 'YOUR_CONTRACT_HELPER_NAME';

    const { deployer } = await getNamedAccounts();
    await deployAndGetContract({
        contractName: CONTRACT_HELPER_NAME,
        deployments,
        deployer,
    });
};

module.exports.skip = async () => true;
