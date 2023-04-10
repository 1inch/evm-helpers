const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');

describe('TraderJoeHelper', function () {
    before(async function () {
        await network.provider.request({ // take avalanch fork
            method: 'hardhat_reset',
            params: [
                {
                    forking: {
                        jsonRpcUrl: process.env.AVAX_RPC_URL,
                    },
                },
            ],
        });
    });

    after(async function () {
        await network.provider.request({ // reset back to local network
            method: 'hardhat_reset',
            params: [],
        });
    });

    it('should show some bins for usdc-usdc.e pair', async function () {
        const USDC_USDC_E_POOL_ADDRESS = '0x18332988456C4Bd9ABa6698ec748b331516F5A14';

        const traderJoeHelper = await (await ethers.getContractFactory('TraderJoeHelper')).deploy();
        await traderJoeHelper.deployed();

        const { data, i } = await traderJoeHelper.getBins(USDC_USDC_E_POOL_ADDRESS, 0, 10);
        console.log('bins length', data.length);
        console.log('i', i);
        expect(data.length).to.gt(0);
    });
});
