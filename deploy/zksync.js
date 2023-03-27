const { Wallet } = require('zksync-web3');
const { Deployer } = require('@matterlabs/hardhat-zksync-deploy');

const OWNER = '0xa3Bf91a131fccfECc43999C9ff4612a25a572859';

module.exports = async (hre) => {
    console.log('running deploy script');
    console.log('network id ', await hre.getChainId());

    // Initialize the wallet.
    const wallet = new Wallet(process.env.ZKSYNC_PRIVATE_KEY);

    // Create deployer object and load the artifact of the contract we want to deploy.
    const deployer = new Deployer(hre, wallet);

    const EvmHelpers = await deployer.loadArtifact('EvmHelpers');
    const evmHelpers = await deployer.deploy(EvmHelpers);
    console.log(`${EvmHelpers.contractName} was deployed to ${evmHelpers.address}`);
    if (await hre.getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: evmHelpers.address,
        });
    }

    const LeftoverExchanger = await deployer.loadArtifact('LeftoverExchanger');
    const leftoverExchanger = await deployer.deploy(LeftoverExchanger, [OWNER]);
    console.log(`${LeftoverExchanger.contractName} was deployed to ${leftoverExchanger.address}`);
    if (await hre.getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: leftoverExchanger.address,
            constructorArguments: [OWNER],
        });
    }
};

module.exports.skip = async () => true;
