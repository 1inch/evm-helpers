const constants = require('../../config/constants');

async function deployFeeCollectorForOperator(hre, chainId, feeCollectorOperatorName, operatorAddress) {
    const { ethers } = hre;

    console.log('Deploying FeeCollector for operator name:', feeCollectorOperatorName);

    const salt = feeCollectorOperatorName.startsWith('0x')
        ? feeCollectorOperatorName
        : ethers.keccak256(ethers.toUtf8Bytes(feeCollectorOperatorName));

    console.log(`Using salt ${salt} for operator ${feeCollectorOperatorName}`);

    const feeCollectorFactory = await ethers.getContractAt('FeeCollectorFactory', constants.FEE_COLLECTOR_FACTORY[chainId]);
    const deployTx = await feeCollectorFactory.deployFeeCollector(salt);
    await deployTx.wait();

    const feeCollectorAddress = await feeCollectorFactory.getFeeCollectorAddress(salt);
    console.log('FeeCollector deployed at', feeCollectorAddress);

    const feeCollector = await ethers.getContractAt('FeeCollector', feeCollectorAddress);
    tx = await feeCollector.setOperator(operatorAddress);
    await tx.wait();
    console.log('feeCollectorOperator set to', operatorAddress);

    return feeCollectorAddress;
}

module.exports = { deployFeeCollectorForOperator };
module.exports.skip = async () => true;