const fs = require('fs');
const path = require('path');
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

    const { feeCollectorOperatorName, feeCollectorOperator } = config.deployOpts;

    if (!feeCollectorOperatorName || !feeCollectorOperator) {
        console.log('Skipping deployment as feeCollectorOperatorName or feeCollectorOperator is not set');
        return;
    }

    const feeCollectorAddress = await deployFeeCollectorForOperator(hre, chainId, feeCollectorOperatorName, feeCollectorOperator);

    const envOutputsPath = path.join(__dirname, '../.env.outputs');
    fs.appendFileSync(envOutputsPath, `OPS_FEE_COLLECTOR_INSTANCE_ADDRESS=${feeCollectorAddress}\n`);
    console.log(`Wrote OPS_FEE_COLLECTOR_INSTANCE_ADDRESS=${feeCollectorAddress} to .env.outputs`);
};

module.exports.skip = async () => true;
