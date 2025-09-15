const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

const LEFTOVER_EXCHANGER_SALT = ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));

const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

module.exports = async ({ getNamedAccounts, deployments }) => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    const leftoverExchangerImpl = await deploy(
        'LeftoverExchangerImpl', 
        { args: [constants.WETH[chainId], constants.LEFTOVER_EXCHANGER_OWNER[chainId]], from: deployer, contract: 'LeftoverExchanger' }
    );
    console.log('LeftoverExchangerImpl deployed to:', leftoverExchangerImpl.address);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);

    const TransparentProxyFactory = await ethers.getContractFactory('TransparentUpgradeableProxy');

    const deployData = (await TransparentProxyFactory.getDeployTransaction(
        leftoverExchangerImpl.address,
        deployer,
        '0x',
    )).data;

    const deployTxn = await create3Deployer.deploy(LEFTOVER_EXCHANGER_SALT, deployData);
    await deployTxn.wait();

    console.log(`LeftoverExchanger proxy deployed to: ${await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT)}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT),
            constructorArguments: [leftoverExchangerImpl.address, deployer, '0x'],
        });

        await hre.run('verify:verify', {
            address: leftoverExchangerImpl.address,
            constructorArguments: [WETH[chainId], constants.LEFTOVER_EXCHANGER_OWNER[chainId]],
        });

        const proxyAdminBytes32 = await ethers.provider.send('eth_getStorageAt', [
            await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT),
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
