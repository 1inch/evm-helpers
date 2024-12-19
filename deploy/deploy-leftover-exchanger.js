const hre = require('hardhat');
const { getChainId, ethers } = hre;

const WETH = {
    1: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // Mainnet
    56: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c', // BSC
    137: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', // Matic
    42161: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1', // Arbitrum
    10: '0x4200000000000000000000000000000000000006', // Optimistic
    43114: '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7', // Avalanche
    100: '0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d', // xDAI
    250: '0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83', // FTM
    1313161554: '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB', // Aurora
    8217: '0xe4f05A66Ec68B54A58B17c22107b02e0232cC817', // Klaytn
    8453: '0x4200000000000000000000000000000000000006', // Base
    59144: '0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f', // Linea
    31337: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // Hardhat
};

const ADMIN_OWNER = {
    1: '0x9F8102b1bB05785BaD2874f2C7B1aaea4c6D976a', // Mainnet
    56: '0x7a4C2f97069f874A355607eBC52aEfCc4eAc9202', // BSC
    137: '0xA154B43EEa8905Ef684995424fF476656ab50A61', // Matic
    42161: '0x0f6E3fB5D73AFd2e594AC4b962E57E603E650875', // Arbitrum
    10: '0x5B18c756F4D9B54255a17BF120da2cF74743247f', // Optimistic
    43114: '0x3b26f6325868Ddd8CB223Ac766cE02a2906653A5', // Avalanche
    100: '0x9e05fA5A389D782C17369a76d8e59A268973275F', // xDAI
    250: '0x0dBa0Da8C5642Db20fEAc06b7A6E9e08e6E501C6', // FTM
    1313161554: '0x0e9292Ff8be5bA8075bE05F5F155E10422AE8017', // Aurora
    // 8217: '', // no Safe on Klaytn
    8453: '0xa4659995DC39d891C1bA9131Aaf5F000E5B57224', // Base
    59144: '0x9cCf4d6B76976Ab11CF9f9219A38BA28983A9a27', // Linea
    31337: '0x9F8102b1bB05785BaD2874f2C7B1aaea4c6D976a', // Hardhat
};

const CREATE3_DEPLOYER_CONTRACT = '0x65B3Db8bAeF0215A1F9B14c506D2a3078b2C84AE';
const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

const LEFTOVER_EXCHANGER_OWNER = '0x2d2d58933e62ed68794d3c337a4d3bc24809ceb2';
const LEFTOVER_EXCHANGER_SALT = ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));
const FEE_COLLECTOR_SAFE_OWNER = '0xa98f85f55f259ef41548251c93409f1d60e804e4';
const FEE_COLLECTOR_SAFE_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollectorSafe'));

async function deployLeftoverExchanger (deployer, deploy, chainId, owner, salt, name, contract) {
    const contractImpl = await deploy(`${name}Impl`, { args: [WETH[chainId], owner], from: deployer, contract });
    console.log(`${name}Impl deployed to:`, contractImpl.address);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', CREATE3_DEPLOYER_CONTRACT);

    const TransparentProxyFactory = await ethers.getContractFactory('TransparentUpgradeableProxy');

    const deployData = (await TransparentProxyFactory.getDeployTransaction(
        contractImpl.address,
        ADMIN_OWNER[chainId],
        '0x',
    )).data;

    const deployTxn = await create3Deployer.deploy(salt, deployData);
    await deployTxn.wait();

    console.log(`${name} proxy deployed to: ${await create3Deployer.addressOf(salt)}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: await create3Deployer.addressOf(salt),
            constructorArguments: [contractImpl.address, ADMIN_OWNER[chainId], '0x'],
        });
        
        await hre.run('verify:verify', {
            address: contractImpl.address,
            constructorArguments: [WETH[chainId], owner],
        });

        const proxyAdminBytes32 = await ethers.provider.send('eth_getStorageAt', [
            await create3Deployer.addressOf(salt),
            ADMIN_SLOT,
            'latest',
        ]);

        const admin = await ethers.getContractAt('ProxyAdmin', '0x' + proxyAdminBytes32.substring(26, 66));

        await hre.run('verify:verify', {
            address: await admin.getAddress(),
            constructorArguments: [ADMIN_OWNER[chainId]],
        });
    }
}

module.exports = async ({ getNamedAccounts, deployments }) => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    await deployLeftoverExchanger(deployer, deploy, chainId, LEFTOVER_EXCHANGER_OWNER, LEFTOVER_EXCHANGER_SALT, 'LeftoverExchanger', 'LeftoverExchanger');
    await deployLeftoverExchanger(deployer, deploy, chainId, FEE_COLLECTOR_SAFE_OWNER, FEE_COLLECTOR_SAFE_SALT, 'FeeCollectorSafe', 'FeeCollector');
};

module.exports.skip = async () => true;
