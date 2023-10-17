const { ethers, network } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');

describe('SolidlyV3Helper', function () {
    before(async function () {
        await network.provider.request({ // take mainnet fork
            method: 'hardhat_reset',
            params: [
                {
                    forking: {
                        jsonRpcUrl: process.env.MAINNET_RPC_URL,
                        httpHeaders: {
                            'auth-key': process.env.RPC_AUTH_HEADER,
                        },
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
        const USDC_WETH_POOL_ADDRESS = '0xafed85453681dc387ee0e87b542614722ee2cfed';

        const solidlyV3Helper = await (await ethers.getContractFactory('SolidlyV3Helper')).deploy();
        await solidlyV3Helper.deployed();

        const ticks = await solidlyV3Helper.getTicks(USDC_WETH_POOL_ADDRESS, 20);
        console.log('ticks', ticks.length);
        expect(ticks.length).to.gt(0);
    });
});
