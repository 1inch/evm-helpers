const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');

describe('UniV3Helper', function () {
    before(async function () {
        await network.provider.request({ // take mainnet fork
            method: 'hardhat_reset',
            params: [
                {
                    forking: {
                        jsonRpcUrl: process.env.MAINNET_RPC_URL,
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

    it('should show some ticks for dai-usdc pair', async function () {
        const USDC_DAI_POOL_ADDRESS = '0x6c6Bc977E13Df9b0de53b251522280BB72383700';

        const uniV3Helper = await (await ethers.getContractFactory('UniV3Helper')).deploy();
        await uniV3Helper.deployed();

        const ticks = await uniV3Helper.getTicks(USDC_DAI_POOL_ADDRESS, 20);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
