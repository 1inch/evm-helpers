const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

const OWNER = '0x2d2d58933e62ed68794d3c337a4d3bc24809ceb2';

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

    const leftoverExchangerImpl = await deploy(
        'LeftoverExchangerImpl', 
        { args: [constants.WETH[chainId], OWNER], from: deployer, contract: 'LeftoverExchanger' }
    );
    console.log('LeftoverExchangerImpl deployed to:', leftoverExchangerImpl.address);

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);
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
            constructorArguments: [constants.WETH[chainId], OWNER],
        });
    }
};

module.exports.skip = async () => true;
