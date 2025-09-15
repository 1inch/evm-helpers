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
        const STS_WS_POOL_ADDRESS = '0xd760791b29e7894fb827a94ca433254bb5afb653';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraSonicHelper')).deploy();
        await algebraHelper.waitForDeployment();

        const ticks = await algebraHelper.getTicks(STS_WS_POOL_ADDRESS, 100);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
