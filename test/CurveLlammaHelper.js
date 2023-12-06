const { ethers, network } = require('hardhat');

describe('CurveLlammaHelper', function () {
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

    it('should show some ticks for sFRX-crvUSD pair', async function () {
        const SFRX_CRVUSD_POOL_ADDRESS = '0x136e783846ef68C8Bd00a3369F787dF8d683a696';

        const curveLlammaHelper = await (await ethers.getContractFactory('CurveLlammaHelper')).deploy();
        await curveLlammaHelper.waitForDeployment();

        const data = await curveLlammaHelper.get(SFRX_CRVUSD_POOL_ADDRESS);
        console.log(data);
    }).timeout(500000);
});
