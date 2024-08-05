const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');
const { ethers, network } = require('hardhat');

describe('CurveLlammaHelper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'mainnet');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some ticks for sFRX-crvUSD pair', async function () {
        const SFRX_CRVUSD_POOL_ADDRESS = '0x136e783846ef68C8Bd00a3369F787dF8d683a696';

        const curveLlammaHelper = await (await ethers.getContractFactory('CurveLlammaHelper')).deploy();
        await curveLlammaHelper.waitForDeployment();

        const data = await curveLlammaHelper.get(SFRX_CRVUSD_POOL_ADDRESS);
        console.log(data);
    }).timeout(500000);
});
