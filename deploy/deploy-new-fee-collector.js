const hre = require('hardhat');
const { getChainId, ethers } = hre;

const FEE_COLLECTOR_FACTORY = {
    1: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Mainnet
    56: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // BSC
    137: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Matic
    42161: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Arbitrum
    10: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Optimistic
    43114: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Avalanche
    100: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // xDAI
    250: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // FTM
    1313161554: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Aurora
    8217: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Klaytn
    8453: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Base
    59144: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Linea
    324: '0x0a479E2ac6d90e15d3c1Fae861b84260D7D4fadb', // zksync
    146: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Sonic
    130: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Unichain
    31337: '0xD25c6f0293d41758552b0B27d6F69353a1134d51', // Hardhat
};

module.exports = async () => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const salt = ethers.keccak256(ethers.toUtf8Bytes('')); // Use correct salt, for instance: from `deploy/upgrade-fee-collector.js`

    const feeCollectorFactory = await ethers.getContractAt('FeeCollectorFactory', FEE_COLLECTOR_FACTORY[chainId]);
    await feeCollectorFactory.deployFeeCollector(salt);
    const feeCollectorAddress = await feeCollectorFactory.getFeeCollectorAddress(salt);
    console.log('FeeCollector deployed at', feeCollectorAddress);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: feeCollectorAddress,
            constructorArguments: [FEE_COLLECTOR_FACTORY[chainId], '0x'],
        });
    }

    // const OPERATOR = '0x...'; // Replace with the actual operator address
    // const feeCollector = await ethers.getContractAt('FeeCollector', feeCollectorAddress);
    // await feeCollector.setOperator(OPERATOR);
};

module.exports.skip = async () => true;
