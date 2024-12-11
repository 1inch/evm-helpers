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

const OWNER = '0x2d2d58933e62ed68794d3c337a4d3bc24809ceb2';
const CREATE3_DEPLOYER_CONTRACT = '0x65B3Db8bAeF0215A1F9B14c506D2a3078b2C84AE';

const LEFTOVER_EXCHANGER_SALT = ethers.keccak256(ethers.toUtf8Bytes('LeftoverExchanger'));

const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

module.exports = async ({ getNamedAccounts, deployments }) => {
    const networkName = hre.network.name;
    console.log(`running ${networkName} deploy script`);
    const chainId = await getChainId();
    console.log('network id ', chainId);
    if (
        networkName in hre.config.networks[networkName] &&
        chainId !== hre.config.networks[networkName].chainId.toString()
    ) {
        console.log(`network chain id: ${hre.config.networks[networkName].chainId}, your chain id ${chainId}`);
        console.log('skipping wrong chain id deployment');
        return;
    }

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    const leftoverExchangerImpl = await deploy('LeftoverExchangerImpl', { args: [WETH[chainId], OWNER], from: deployer, contract: 'LeftoverExchanger' });
    console.log('LeftoverExchangerImpl deployed to:', leftoverExchangerImpl.address);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', CREATE3_DEPLOYER_CONTRACT);
    const proxy = await ethers.getContractAt('TransparentUpgradeableProxy', await create3Deployer.addressOf(LEFTOVER_EXCHANGER_SALT));
    const adminAddress = '0x' + (await ethers.provider.send('eth_getStorageAt', [
        await proxy.getAddress(),
        ADMIN_SLOT,
        'latest',
    ])).substring(26, 66);
    const admin = await ethers.getContractAt('ProxyAdmin', adminAddress);

    const upgradeTxn = await admin.upgradeAndCall(await proxy.getAddress(), leftoverExchangerImpl.address, '0x');
    await upgradeTxn.wait();

    console.log('Proxy upgraded');

    if (await getChainId() !== '31337') {
        await sleep(5000); // wait for etherscan to index contract

        await hre.run('verify:verify', {
            address: leftoverExchangerImpl.address,
            constructorArguments: [WETH[chainId], OWNER],
        });
    }
};

module.exports.skip = async () => true;
