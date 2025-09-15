const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

const EVM_HELPERS_SALT = ethers.keccak256(ethers.toUtf8Bytes('EvmHelpers-new'));

module.exports = async () => {
    console.log('running deploy script');

    const chainId = await getChainId();
    console.log('network id ', chainId);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);

    const EvmHelpersFactory = await ethers.getContractFactory('EvmHelpers');

    const deployData = (await EvmHelpersFactory.getDeployTransaction()).data;

    const deployTxn = await create3Deployer.deploy(EVM_HELPERS_SALT, deployData, { gasLimit: 5000000 });
    await deployTxn.wait();

    const evmHelpersAddress = await create3Deployer.addressOf(EVM_HELPERS_SALT);

    console.log(`EvmHelpers deployed to: ${evmHelpersAddress}`);

    await new Promise(resolve => setTimeout(resolve, 3000));

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', { address: evmHelpersAddress });
    }
};

module.exports.skip = async () => true;
