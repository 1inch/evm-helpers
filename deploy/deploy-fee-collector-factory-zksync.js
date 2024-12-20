const hre = require('hardhat');
const { getChainId } = hre;

const WETH = {
    324: '0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91', // zksync
    31337: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // Hardhat
};

const FEE_COLLECTOR_FACTORY_OWNER = {
    324: '0x5cEf041D1C3198Ce7F9D5E0521867e670da7520e', // zksync
    31337: '0x9F8102b1bB05785BaD2874f2C7B1aaea4c6D976a', // Hardhat
};

const LOP = '0x6fd4383cB451173D5f9304F041C7BCBf27d561fF';

const FEE_COLLECTOR_OWNER = '0xa98f85f55f259ef41548251c93409f1d60e804e4';

module.exports = async () => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    const feeCollector = await deploy('FeeCollector', { args: [WETH[chainId], LOP, FEE_COLLECTOR_OWNER], from: deployer });

    console.log(`FeeCollector impl deployed to: ${feeCollector.address}`);

    const feeCollectorFactory = await deploy('FeeCollectorFactory', { args: [feeCollector.address, FEE_COLLECTOR_FACTORY_OWNER[chainId]], from: deployer });

    console.log(`FeeCollectorFactory deployed to: ${feeCollectorFactory.address}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: feeCollector.address,
            constructorArguments: [WETH[chainId], LOP, FEE_COLLECTOR_OWNER],
        });

        await hre.run('verify:verify', {
            address: feeCollectorFactory.address,
            constructorArguments: [feeCollector.address, FEE_COLLECTOR_FACTORY_OWNER[chainId]],
        });
    }
};

module.exports.skip = async () => true;
