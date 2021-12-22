const hre = require('hardhat');
const { getChainId } = hre;

module.exports = async ({ deployments, getNamedAccounts }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const evmHelpers = await deploy('EvmHelpers', {
        from: deployer,
    });

    console.log('EvmHelpers deployed to:', evmHelpers.address);

    if (await getChainId() !== '31337') {
        await hre.run('verify:verify', {
            address: evmHelpers.address,
        });
    }
};

module.exports.skip = async () => false;
