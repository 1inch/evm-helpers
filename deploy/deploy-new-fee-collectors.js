const hre = require('hardhat');
const { getChainId } = hre;
const constants = require('../config/constants');
const { deployFeeCollectorForOperator } = require('./helpers/deploy-fee-collector-for-operator');

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
        if (!constants.FEE_COLLECTOR_OPERATOR?.[chainId]?.[feeCollectorOperatorName]) {
            console.log(`Skipping deployment on chain ${chainId} as no operator is set for name ${feeCollectorOperatorName}`);
            continue;
        }

        const operatorAddress = constants.FEE_COLLECTOR_OPERATOR[chainId][feeCollectorOperatorName];
        await deployFeeCollectorForOperator(hre, chainId, feeCollectorOperatorName, operatorAddress);
    }
};

module.exports.skip = async () => true;
