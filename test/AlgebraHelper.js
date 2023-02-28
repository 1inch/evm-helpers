const { ethers, network } = require('hardhat');

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

    it('should show some ticks for dai-usdc pair', async function () {
        const USDC_DAI_POOL_ADDRESS = '0x873c8Fc75d6139480882D42C3F9E4283627250D7';

        const algebraHelper = await (await ethers.getContractFactory('AlgebraHelper')).deploy();
        await algebraHelper.deployed();

        const ticks = await algebraHelper.getTicks(USDC_DAI_POOL_ADDRESS, 1000);
        console.log('ticks', ticks);
        expect(ticks.length).to.gt(0);
    });
});
