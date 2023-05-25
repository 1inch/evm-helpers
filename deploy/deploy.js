const hre = require('hardhat');
const { getChainId } = hre;

module.exports = async ({ deployments, getNamedAccounts }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    // const { deploy } = deployments;
    // const { deployer } = await getNamedAccounts();

    // const evmHelpers = await deploy('EvmHelpers', {
    //     from: deployer,
    // });

    // console.log('EvmHelpers deployed to:', evmHelpers.address);

    // if (await getChainId() !== '31337') {
    //     await hre.run('verify:verify', {
    //         address: evmHelpers.address,
    //     });
    // }

    // const traderJoeHelper = await deploy('TraderJoeHelper', {
    //     from: deployer,
    // });

    // console.log('TraderJoeHelper deployed to:', traderJoeHelper.address);

    // if (await getChainId() !== '31337') {
    //     await hre.run('verify:verify', {
    //         address: traderJoeHelper.address,
    //     });
    // }

    // const algebraHelper = await deploy('AlgebraHelper', {
    //     from: deployer,
    // });

    // console.log('AlgebraHelper deployed to:', algebraHelper.address);

    // if (await getChainId() !== '31337') {
    //     await hre.run('verify:verify', {
    //         address: algebraHelper.address,
    //     });
    // }

    // const taderJoeHelperV2dot1 = await deploy('TraderJoeHelper_v2_1', {
    //     from: deployer,
    // });

    // console.log('TraderJoeHelper_v2_1 deployed to:', taderJoeHelperV2dot1.address);

    // if (await getChainId() !== '31337') {
    //     await hre.run('verify:verify', {
    //         address: taderJoeHelperV2dot1.address,
    //     });
    // }

    // const kyberHelper = await deploy('KyberHelper', {
    //     from: deployer,
    // });

    // console.log('kyberHelper deployed to:', kyberHelper.address);

    // if (await getChainId() !== '31337') {
    //     await hre.run('verify:verify', {
    //         address: kyberHelper.address,
    //     });
    // }
};

module.exports.skip = async () => true;
