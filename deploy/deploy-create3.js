const hre = require('hardhat');
const { getChainId, ethers } = hre;

const CREATE3_DEPLOYER_CONTRACT = '0x65B3Db8bAeF0215A1F9B14c506D2a3078b2C84AE';

const EVM_HELPERS_SALT = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('EvmHelpers-new'));

module.exports = async () => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', CREATE3_DEPLOYER_CONTRACT);

    const EvmHelpersFactory = await ethers.getContractFactory('EvmHelpers');

    const deployData = EvmHelpersFactory.getDeployTransaction().data;

    const deployTxn = await create3Deployer.deploy(EVM_HELPERS_SALT, deployData, { gasLimit: 5000000 });
    await deployTxn.wait();

    const evmHelpersAddress = await create3Deployer.addressOf(EVM_HELPERS_SALT);

    console.log(`EvmHelpers deployed to: ${evmHelpersAddress}`);

    await new Promise(r => setTimeout(r, 3000));

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', { address: evmHelpersAddress });
    }
};

module.exports.skip = async () => true;
