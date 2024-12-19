const hre = require('hardhat');
const { getChainId, ethers } = hre;

const WETH = {
    324: '0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91', // zksync
    31337: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // Hardhat
};

const ADMIN_OWNER = {
    324: '0x5cEf041D1C3198Ce7F9D5E0521867e670da7520e', // zkcync
    31337: '0x9F8102b1bB05785BaD2874f2C7B1aaea4c6D976a', // Hardhat
};

const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';

const LEFTOVER_EXCHANGER_OWNER = '0x2d2d58933e62ed68794d3c337a4d3bc24809ceb2';
const FEE_COLLECTOR_SAFE_OWNER = '0xa98f85f55f259ef41548251c93409f1d60e804e4';

async function deployLeftoverExchanger (deployer, deploy, chainId, owner, name, contract) {
    const contractImpl = await deploy(`${name}Impl`, { args: [WETH[chainId], owner], from: deployer, contract });
    console.log(`${name}Impl deployed to:`, contractImpl.address);

    const proxy = await deploy(`${name}Proxy`, { args: [contractImpl.address, ADMIN_OWNER[chainId], '0x'], from: deployer, contract: 'TransparentUpgradeableProxy' });

    console.log(`${name} proxy deployed to:`, proxy);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: proxy.address,
            constructorArguments: [contractImpl.address, ADMIN_OWNER[chainId], '0x'],
        });
        
        await hre.run('verify:verify', {
            address: contractImpl.address,
            constructorArguments: [WETH[chainId], owner],
        });

        const proxyAdminBytes32 = await ethers.provider.send('eth_getStorageAt', [
            proxy.address,
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

    await deployLeftoverExchanger(deployer, deploy, chainId, LEFTOVER_EXCHANGER_OWNER, 'LeftoverExchanger', 'LeftoverExchanger');
    await deployLeftoverExchanger(deployer, deploy, chainId, FEE_COLLECTOR_SAFE_OWNER, 'FeeCollectorSafe', 'FeeCollector');
};

module.exports.skip = async () => true;
