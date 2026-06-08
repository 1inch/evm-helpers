const { deployAndGetContractWithCreate3 } = require('@1inch/solidity-utils');
const hre = require('hardhat');
const { getChainId, ethers } = hre;

const constants = require('../config/constants');

module.exports = async ({ deployments }) => {
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

    const feeCollectorSalt = constants.FEE_COLLECTOR_SALT[chainId] ?? 'feeCollector';
    const feeCollectorFactorySalt = constants.FEE_COLLECTOR_FACTORY_SALT[chainId] ?? 'feeCollectorFactory';

    const FEE_COLLECTOR_SALT = ethers.keccak256(ethers.toUtf8Bytes(feeCollectorSalt));
    const FEE_COLLECTOR_FACTORY_SALT = ethers.keccak256(ethers.toUtf8Bytes(feeCollectorFactorySalt));

    console.log('Deploying implementation with salt:', feeCollectorSalt);

    const feeCollector = await deployAndGetContractWithCreate3({
        contractName: 'FeeCollector',
        constructorArgs: [constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId]],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: FEE_COLLECTOR_SALT,
        deployments,
        skipVerify: process.env.OPS_SKIP_VERIFY === 'true',
    });

    console.log('Deploying factory with salt:', feeCollectorFactorySalt);

    await deployAndGetContractWithCreate3({
        contractName: 'FeeCollectorFactory',
        constructorArgs: [await feeCollector.getAddress(), constants.FEE_COLLECTOR_FACTORY_OWNER[chainId]],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: FEE_COLLECTOR_FACTORY_SALT,
        deployments,
        skipVerify: process.env.OPS_SKIP_VERIFY === 'true',
    });
};

module.exports.skip = async () => true;
