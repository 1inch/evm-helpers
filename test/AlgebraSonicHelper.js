const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('AlgebraSonicHelper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'sonic');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some ticks for weth-ws pair', async function () {
        const WETH_WS_POOL_ADDRESS = '0xF58fC088C33aD46113940173cB0da3Dd08c4AA88';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraSonicHelper')).deploy();
        await algebraHelper.waitForDeployment();

        const ticks = await algebraHelper.getTicks(WETH_WS_POOL_ADDRESS, 1000);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
