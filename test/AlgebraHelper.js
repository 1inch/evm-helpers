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
        const USDC_WETH_POOL_ADDRESS = '0xdEb89DE4bb6ecf5BFeD581EB049308b52d9b2Da7';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraHelper')).deploy();
        await algebraHelper.waitForDeployment();

        const ticks = await algebraHelper.getTicks(USDC_WETH_POOL_ADDRESS, 100);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
