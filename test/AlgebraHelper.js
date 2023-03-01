const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');

describe('AlgebraHelper', function () {
    before(async function () {
        await network.provider.request({ // take arbitrum fork
            method: 'hardhat_reset',
            params: [
                {
                    forking: {
                        jsonRpcUrl: process.env.ARBITRUM_RPC_URL,
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

    it('should show some ticks for weth-usdc pair', async function () {
        const USDC_WETH_POOL_ADDRESS = '0x308C5B91F63307439FDB51a9fA4Dfc979E2ED6B0';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraHelper')).deploy();
        await algebraHelper.deployed();

        const ticks = await algebraHelper.getTicks(USDC_WETH_POOL_ADDRESS, 10);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
