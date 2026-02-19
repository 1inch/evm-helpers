const hre = require('hardhat');
const { getChainId, ethers } = hre;
const { deployAndGetContract, deployAndGetContractWithCreate3 } = require('@1inch/solidity-utils');

const constants = require('../config/constants');

module.exports = async ({ deployments, getNamedAccounts, config }) => {
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

    let DEPLOYMENT_METHOD = config.deployOpts?.deploymentMethod || 'create3';

    if (chainId === '324') { // create3 is not supported for zksync
        DEPLOYMENT_METHOD = 'create';
    }

    for (const contractHelperConfig of config.deployOpts.contractHelperConfigs) {
        const contractHelperName = contractHelperConfig.name;
        console.log('Deploying contract helper for name:', contractHelperName);

        let result;

        if (DEPLOYMENT_METHOD === 'create3') {
            const salt = contractHelperConfig.salt
                ? contractHelperConfig.salt.startsWith('0x')
                    ? contractHelperConfig.salt
                    : ethers.keccak256(ethers.toUtf8Bytes(contractHelperConfig.salt))
                : ethers.keccak256(ethers.toUtf8Bytes(contractHelperName));

            console.log(`Using salt ${salt} for contract ${contractHelperName}`);

            if (!constants.CREATE3_DEPLOYER_CONTRACT?.[chainId]) {
                console.log(`Skipping deployment on chain ${chainId} as no Create3Deployer is set`);
                continue;
            }

            result = await deployAndGetContractWithCreate3({
                contractName: contractHelperName,
                constructorArgs: constants.CONSTRUCTOR_ARGS?.[contractHelperName]?.[chainId] ?? [],
                deploymentName: contractHelperName,
                create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
                salt,
                deployments,
                skipVerify: process.env.OPS_SKIP_VERIFY === 'true',
            });
        } else {
            const { deployer } = await getNamedAccounts();

            result = await deployAndGetContract({
                contractName: contractHelperName,
                deployments,
                deployer,
                constructorArgs: constants.CONSTRUCTOR_ARGS?.[contractHelperName]?.[chainId] ?? [],
                skipVerify: process.env.OPS_SKIP_VERIFY === 'true',
            });
        }

        console.log(`Address for ${contractHelperName}: ${await result.getAddress()}`);
    }
};

module.exports.skip = async () => true;
