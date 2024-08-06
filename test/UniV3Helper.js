const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('UniV3Helper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'mainnet');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some ticks for dai-usdc pair', async function () {
        const USDC_DAI_POOL_ADDRESS = '0x6c6Bc977E13Df9b0de53b251522280BB72383700';

        const uniV3Helper = await (await ethers.getContractFactory('UniV3Helper')).deploy();
        await uniV3Helper.waitForDeployment();

        const ticks = await uniV3Helper.getTicks(USDC_DAI_POOL_ADDRESS, 20);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
