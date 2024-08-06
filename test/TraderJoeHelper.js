const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');

describe('TraderJoeHelper', function () {
    before(async function () {
        await resetHardhatNetworkFork(network, 'avax');
    });

    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    it('should show some bins for usdc-usdc.e pair', async function () {
        const USDC_USDC_E_POOL_ADDRESS = '0x18332988456C4Bd9ABa6698ec748b331516F5A14';

        const traderJoeHelper = await (await ethers.getContractFactory('TraderJoeHelper')).deploy();
        await traderJoeHelper.waitForDeployment();

        const { data, i } = await traderJoeHelper.getBins(USDC_USDC_E_POOL_ADDRESS, 0, 10);
        console.log('bins length', data.length);
        console.log('i', i);
        expect(data.length).to.gt(0);
    });
});
