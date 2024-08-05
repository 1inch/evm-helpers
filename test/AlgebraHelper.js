const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('AlgebraHelper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'arbitrum');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some ticks for weth-usdc pair', async function () {
        const USDC_WETH_POOL_ADDRESS = '0x308C5B91F63307439FDB51a9fA4Dfc979E2ED6B0';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraHelper')).deploy();
        await algebraHelper.waitForDeployment();

        const ticks = await algebraHelper.getTicks(USDC_WETH_POOL_ADDRESS, 10);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
