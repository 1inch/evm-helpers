const { deployAndGetContractWithCreate3 } = require('@1inch/solidity-utils');
const hre = require('hardhat');
const { getChainId, ethers } = hre;

const constants = require('./constants');

const FEE_COLLECTOR_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollector'));
const FEE_COLLECTOR_FACTORY_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollectorFactory'));

module.exports = async ({ deployments }) => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const feeCollector = await deployAndGetContractWithCreate3({
        contractName: 'FeeCollector',
        constructorArgs: [constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId]],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: FEE_COLLECTOR_SALT,
        deployments,
    });

    await deployAndGetContractWithCreate3({
        contractName: 'FeeCollectorFactory',
        constructorArgs: [await feeCollector.getAddress(), constants.FEE_COLLECTOR_FACTORY_OWNER[chainId]],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: FEE_COLLECTOR_FACTORY_SALT,
        deployments,
    });
};

module.exports.skip = async () => true;
