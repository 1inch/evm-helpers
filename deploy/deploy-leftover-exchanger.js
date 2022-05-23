const hre = require('hardhat');
const { getChainId } = hre;

const OWNER = '0xa3bf91a131fccfecc43999c9ff4612a25a572859';

module.exports = async ({ deployments, getNamedAccounts }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const leftoverExchanger = await deploy('LeftoverExchanger', {
        from: deployer,
        args: [OWNER],
    });

    console.log('LeftoverExchanger deployed to:', leftoverExchanger.address);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: leftoverExchanger.address,
            constructorArguments: [OWNER],
        });
    }
};

module.exports.skip = async () => true;
