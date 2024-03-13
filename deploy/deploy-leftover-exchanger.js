const hre = require('hardhat');
const { getChainId, ethers } = hre;

const OWNER = '0xa3bf91a131fccfecc43999c9ff4612a25a572859';
const CREATE3_DEPLOYER_CONTRACT = '0x65B3Db8bAeF0215A1F9B14c506D2a3078b2C84AE';

const LEFTOVER_EXCHANGER_SALT = ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));

const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

module.exports = async ({ getNamedAccounts, deployments }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    const leftoverExchangerImpl = await deploy('LeftoverExchangerImpl', { args: [OWNER], from: deployer, contract: 'LeftoverExchanger' });
    console.log('LeftoverExchangerImpl deployed to:', leftoverExchangerImpl.address);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', CREATE3_DEPLOYER_CONTRACT);

    const DestroyerFactory = await ethers.getContractFactory('Destroyer');
    const destroyer = DestroyerFactory.attach(await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT));

    console.log('Deployer balance: ', ethers.formatEther(await ethers.provider.getBalance(deployer)));

    const leftoverExchangerDestroyTxn = await destroyer.destroy();
    await leftoverExchangerDestroyTxn.wait();

    console.log('LeftoverExchanger destroyed');

    console.log('Deployer balance: ', ethers.formatEther(await ethers.provider.getBalance(deployer)));

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
            constructorArguments: [OWNER],
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
