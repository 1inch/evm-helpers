const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('../config/constants');
const { deployAndGetContractWithCreate3 } = require('@1inch/solidity-utils');

const FEE_COLLECTOR_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollector_v2'));
const FEE_COLLECTOR_FACTORY_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollectorFactory'));

module.exports = async ({ deployments }) => {
    const networkName = hre.network.name;
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    if (
        networkName in hre.config.networks &&
        chainId !== hre.config.networks[networkName].chainId?.toString()
    ) {
        console.log(`network chain id: ${hre.config.networks[networkName].chainId}, your chain id ${chainId}`);
        console.log('skipping wrong chain id deployment');
        return;
    }

    const OPERATORS = constants.FEE_COLLECTOR_OPERATOR[chainId];

    await deployAndGetContractWithCreate3({
        contractName: 'FeeCollector',
        constructorArgs: [constants.WETH[chainId], constants.LOP[chainId], constants.FEE_COLLECTOR_OWNER[chainId]],
        create3Deployer: constants.CREATE3_DEPLOYER_CONTRACT[chainId],
        salt: FEE_COLLECTOR_SALT,
        deployments,
    });

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);
    const feeCollectorFactory = await ethers.getContractAt(
        'FeeCollectorFactory',
        await create3Deployer.addressOf(FEE_COLLECTOR_FACTORY_SALT),
    );

    console.log(
        'upgradeTo is required: %s .upgradeTo(%s)',
        feeCollectorFactory.target,
        await create3Deployer.addressOf(FEE_COLLECTOR_SALT),
    );

    for (const [fcType, operator] of Object.entries(OPERATORS)) {
        const salt = ethers.keccak256(ethers.toUtf8Bytes(fcType));
        const fc = await feeCollectorFactory.getFeeCollectorAddress(salt);

        console.log(
            'setOperator for "%s" is required: %s .setOperator(%s)',
            fcType,
            fc,
            operator,
        );
    }
};

module.exports.skip = async () => true;
