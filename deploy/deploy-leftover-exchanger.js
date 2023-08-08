const hre = require('hardhat');
const { getChainId, ethers } = hre;

const OWNER = '0xa3bf91a131fccfecc43999c9ff4612a25a572859';
const CREATE3_DEPLOYER_CONTRACT = '0x65B3Db8bAeF0215A1F9B14c506D2a3078b2C84AE';

const LEFTOVER_EXCHANGER_SALT = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('LeftoverExchanger'));

module.exports = async ({ getNamedAccounts }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const { deployer } = await getNamedAccounts();

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', CREATE3_DEPLOYER_CONTRACT);

    const LeftoverExchangerFactory = await ethers.getContractFactory('LeftoverExchanger');

    const leftoverExchanger = LeftoverExchangerFactory.attach(await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT));

    const leftoverExchangerDestroyTxn = await leftoverExchanger.destroy();
    await leftoverExchangerDestroyTxn.wait();

    console.log('LeftoverExchanger destroyed');

    const deployData = LeftoverExchangerFactory.getDeployTransaction(OWNER, deployer).data;

    const deployTxn = await create3Deployer.deploy(LEFTOVER_EXCHANGER_SALT, deployData);
    await deployTxn.wait();

    console.log(`LeftoverExchanger deployed to: ${leftoverExchanger.address}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: leftoverExchanger.address,
            constructorArguments: [OWNER, deployer],
        });
    }
};

module.exports.skip = async () => true;
