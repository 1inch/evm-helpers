const hre = require('hardhat');
const { getChainId, ethers } = hre;
const constants = require('./constants');

const FEE_COLLECTOR_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollector_v2'));
const FEE_COLLECTOR_FACTORY_SALT = ethers.keccak256(ethers.toUtf8Bytes('FeeCollectorFactory'));

module.exports = async () => {
    console.log('running deploy script');
    const chainId = await getChainId();
    console.log('network id ', chainId);

    const OPERATORS = constants.FEE_COLLECTOR_OPERATOR[chainId];

    const create3Deployer = await ethers.getContractAt('ICreate3Deployer', constants.CREATE3_DEPLOYER_CONTRACT[chainId]);

    const FeeCollector = await ethers.getContractFactory('FeeCollector');

    const implDeployData = (await FeeCollector.getDeployTransaction(
        constants.WETH[chainId],
        constants.LOP[chainId],
        constants.FEE_COLLECTOR_OWNER[chainId],
    )).data;

    const implDeployTxn = await create3Deployer.deploy(FEE_COLLECTOR_SALT, implDeployData);
    await implDeployTxn.wait();

    console.log(`FeeCollector impl deployed to: ${await create3Deployer.addressOf(FEE_COLLECTOR_SALT)}`);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: await create3Deployer.addressOf(FEE_COLLECTOR_SALT),
            constructorArguments: [
                constants.WETH[chainId],
                constants.LOP[chainId],
                constants.FEE_COLLECTOR_OWNER[chainId],
            ],
        });
    }

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
