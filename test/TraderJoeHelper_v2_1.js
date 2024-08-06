const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('TraderJoeHelper_v2_1', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'avax');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some bins for usdc-dai.e pair', async function () {
        const USDC_DAI_E_POOL_ADDRESS = '0x2f1DA4bafd5f2508EC2e2E425036063A374993B6';

        const traderJoeHelperV2dot1 = await (await ethers.getContractFactory('TraderJoeHelper_v2_1')).deploy();
        await traderJoeHelperV2dot1.waitForDeployment();

        const { data, i } = await traderJoeHelperV2dot1.getBins(USDC_DAI_E_POOL_ADDRESS, 0, 10);
        console.log('bins length', data.length);
        console.log('i', i);
        expect(data.length).to.gt(0);
    });
});
