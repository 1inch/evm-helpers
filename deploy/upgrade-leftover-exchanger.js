const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('../config/constants');
const { deployAndGetContract } = require('@1inch/solidity-utils');

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

    const salt = constants.LEFTOVER_EXCHANGER_SALT[chainId]
        ? constants.LEFTOVER_EXCHANGER_SALT[chainId].startsWith('0x')
            ? constants.LEFTOVER_EXCHANGER_SALT[chainId]
            : ethers.keccak256(ethers.toUtf8Bytes(constants.LEFTOVER_EXCHANGER_SALT[chainId]))
        : ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);
    const proxy = await ethers.getContractAt('TransparentUpgradeableProxy', await create3Deployer.addressOf(salt));
    const adminAddress = '0x' + (await ethers.provider.send('eth_getStorageAt', [
        await proxy.getAddress(),
        ADMIN_SLOT,
        'latest',
    ])).substring(26, 66);
    const admin = await ethers.getContractAt('ProxyAdmin', adminAddress);

    const upgradeTxn = await admin.upgradeAndCall(await proxy.getAddress(), await leftoverExchangerImpl.getAddress(), '0x');
    await upgradeTxn.wait();

    console.log('Proxy upgraded');
};

module.exports.skip = async () => true;
