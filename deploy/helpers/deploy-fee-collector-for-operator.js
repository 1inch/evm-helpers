const constants = require('../../config/constants');

async function deployFeeCollectorForOperator(hre, chainId, feeCollectorOperatorName, operatorAddress) {
    const { ethers } = hre;

    console.log('Deploying FeeCollector for operator name:', feeCollectorOperatorName);

    const salt = feeCollectorOperatorName.startsWith('0x')
        ? feeCollectorOperatorName
        : ethers.keccak256(ethers.toUtf8Bytes(feeCollectorOperatorName));

    console.log(`Using salt ${salt} for operator ${feeCollectorOperatorName}`);

    const feeCollectorFactory = await ethers.getContractAt('FeeCollectorFactory', constants.FEE_COLLECTOR_FACTORY[chainId]);
    await feeCollectorFactory.deployFeeCollector(salt);
    const feeCollectorAddress = await feeCollectorFactory.getFeeCollectorAddress(salt);
    console.log('FeeCollector deployed at', feeCollectorAddress);

    if (chainId !== '31337' && process.env.OPS_SKIP_VERIFY !== 'true') {
        await hre.run('verify:verify', {
            address: feeCollectorAddress,
            constructorArguments: [constants.FEE_COLLECTOR_FACTORY[chainId], '0x'],
        });
    }

    const feeCollector = await ethers.getContractAt('FeeCollector', feeCollectorAddress);
    await feeCollector.setOperator(operatorAddress);
    console.log('feeCollectorOperator set to', feeCollectorAddress);

    return feeCollectorAddress;
}

module.exports = { deployFeeCollectorForOperator };
