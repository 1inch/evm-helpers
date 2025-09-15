const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

module.exports = async ({ config }) => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);
    console.log('deployOpts', config.deployOpts);

    if (!constants.FEE_COLLECTOR_FACTORY[chainId]) {
        console.log(`Skipping deployment on chain ${chainId} as no FeeCollectorFactory is set`);
        return;
    }

    for (const feeCollectorOperatorName of config.deployOpts.feeCollectorOperatorNames) {
        console.log('Deploying FeeCollector for operator name:', feeCollectorOperatorName);

        if (!constants.FEE_COLLECTOR_OPERATOR?.[chainId]?.[feeCollectorOperatorName]) {
            console.log(`Skipping deployment on chain ${chainId} as no operator is set for name ${feeCollectorOperatorName}`);
            continue;
        }

        const salt = ethers.keccak256(ethers.toUtf8Bytes(feeCollectorOperatorName)); // Use correct salt, for instance: from `deploy/upgrade-fee-collector.js`

        const feeCollectorFactory = await ethers.getContractAt('FeeCollectorFactory', constants.FEE_COLLECTOR_FACTORY[chainId]);
        await feeCollectorFactory.deployFeeCollector(salt);
        const feeCollectorAddress = await feeCollectorFactory.getFeeCollectorAddress(salt);
        console.log('FeeCollector deployed at', feeCollectorAddress);

        if (chainId !== '31337') {
            await hre.run('verify:verify', {
                address: feeCollectorAddress,
                constructorArguments: [constants.FEE_COLLECTOR_FACTORY[chainId], '0x'],
            });
        }

        const OPERATOR = constants.FEE_COLLECTOR_OPERATOR[chainId][feeCollectorOperatorName]; // Replace with the actual operator address
        const feeCollector = await ethers.getContractAt('FeeCollector', feeCollectorAddress);
        await feeCollector.setOperator(OPERATOR);
        console.log('feeCollectorOperator set to', feeCollectorAddress);
    }
};

module.exports.skip = async () => true;
