const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('SolidlyV3Helper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'mainnet');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some ticks for weth-usdc pair', async function () {
        const USDC_WETH_POOL_ADDRESS = '0xafed85453681dc387ee0e87b542614722ee2cfed';

        const solidlyV3Helper = await (await ethers.getContractFactory('SolidlyV3Helper')).deploy();
        await solidlyV3Helper.waitForDeployment();

        const ticks = await solidlyV3Helper.getTicks(USDC_WETH_POOL_ADDRESS, 20);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
