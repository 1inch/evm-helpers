const { deployAndGetContractWithCreate3, deployAndGetContract } = require('@1inch/solidity-utils');
const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

const LEFTOVER_EXCHANGER_SALT = ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));
const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

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

    const leftoverExchangerImpl = await deployAndGetContract({
        contractName: 'LeftoverExchanger',
        deploymentName: 'LeftoverExchangerImpl',
        deployments,
        deployer,
        constructorArgs: [constants.WETH[chainId], constants.LEFTOVER_EXCHANGER_OWNER[chainId]],
    });

    const transparentUpgradeableProxy = await deployAndGetContractWithCreate3({
        contractName: 'TransparentUpgradeableProxy',
        deploymentName: 'LeftoverExchanger',
        constructorArgs: [await leftoverExchangerImpl.getAddress(), deployer, '0x'],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: LEFTOVER_EXCHANGER_SALT,
        deployments,
    });

    if (chainId !== '31337') {
        const proxyAdminBytes32 = await ethers.provider.send('eth_getStorageAt', [
            await transparentUpgradeableProxy.getAddress(),
            ADMIN_SLOT,
            'latest',
        ]);

        await hre.run('verify:verify', {
            address: '0x' + proxyAdminBytes32.substring(26, 66),
            constructorArguments: [deployer],
        });
    }
};

module.exports.skip = async () => true;
