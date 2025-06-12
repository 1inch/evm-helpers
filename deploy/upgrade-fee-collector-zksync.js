const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

module.exports = async ({ getNamedAccounts, deployments }) => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    const feeCollector = await deploy(
        'FeeCollector',
        { args: [constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId]], from: deployer },
    );

    console.log(`FeeCollector impl deployed to: ${feeCollector.address}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: feeCollector.address,
            constructorArguments: [
                constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId],
            ],
        });
    }

    const feeCollectorFactory = await ethers.getContractAt('FeeCollectorFactory', constants.FEE_COLLECTOR_FACTORY[chainId]);

    console.log(
        'upgradeTo is required: %s .upgradeTo(%s)',
        feeCollectorFactory.target,
        feeCollector.address,
    );
};

module.exports.skip = async () => true;
