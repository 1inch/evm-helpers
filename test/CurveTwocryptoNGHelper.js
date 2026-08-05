const fs = require('fs');
const path = require('path');
const { expect } = require('chai');
const { resetHardhatNetworkFork } = require('@1inch/solidity-utils/hardhat-setup');
const { ethers, network } = require('hardhat');

// Vyper original (vyper/2crypto_ng_helper.vy), deployed on Arbitrum only.
const VYPER_HELPER = '0xa0f3b13fbd36df6dbeb6e4865dfc2ad3a4b5a12d';
// Twocrypto-NG factory, same address on Arbitrum and Polygon.
const TWOCRYPTO_NG_FACTORY = '0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F';
const PREP_CALC_SELECTOR = '0x70eeb546';
const RESPONSE_SIZE = 288;
// Keeps CI runtime sane; the whole factory was checked offline (125 pools on Arbitrum, 288 on Polygon).
const MAX_POOLS = 25;

// Curve frxUSD pools on Polygon that need this helper (PT3-1130) with their published `A`.
const POLYGON_FRXUSD_POOLS = [
    { name: 'BRZ/frxUSD', address: '0xdCb72c163de84618417Bec9aeF7ae32B5336d70E', a: 500000n },
    { name: 'tGBP/frxUSD', address: '0xF5c83F5f7d3975726527feaDE0e51c6e5ecf7bA5', a: 750000n },
    { name: 'AUDF/frxUSD', address: '0xcb6DCbCb1Da63ACc01e6CC9804d0AEe5a0dbB3Ba', a: 650000n },
    { name: 'frxUSD/KRWQ', address: '0xbaE895c43c3Af0f76E8bED2aF8D1063afCE35F5D', a: 300000n },
    { name: 'IDRX/frxUSD', address: '0x4e89713e0A9971089447d2BEE24b736F00672fEA', a: 250000n },
];

const vyperRuntime = () => fs.readFileSync(path.join(__dirname, 'fixtures', '2crypto_ng_helper.runtime.hex'), 'utf8').trim();

const prepCalc = (helper, pool) => ethers.provider.call({
    to: helper,
    data: PREP_CALC_SELECTOR + ethers.zeroPadValue(pool, 32).slice(2),
});

async function factoryPools () {
    const factory = new ethers.Contract(
        TWOCRYPTO_NG_FACTORY,
        ['function pool_count() view returns (uint256)', 'function pool_list(uint256) view returns (address)'],
        ethers.provider,
    );
    const count = Number(await factory.pool_count());
    const pools = [];
    for (let i = 0; i < Math.min(count, MAX_POOLS); i++) {
        pools.push(await factory.pool_list(i));
    }
    return pools;
}

// `null` means the call reverted; some pools use a math contract without the 4-argument
// `newton_D`, and then BOTH implementations must revert in the very same way.
async function tryPrepCalc (helper, pool) {
    try {
        return await prepCalc(helper, pool);
    } catch {
        return null;
    }
}

async function expectSameResponse (solidityHelper, pool) {
    const [fromVyper, fromSolidity] = await Promise.all([
        tryPrepCalc(VYPER_HELPER, pool),
        tryPrepCalc(solidityHelper, pool),
    ]);
    expect(fromSolidity, `pool ${pool}`).to.be.equal(fromVyper);
    if (fromSolidity !== null) {
        expect((fromSolidity.length - 2) / 2, `pool ${pool} response size`).to.be.equal(RESPONSE_SIZE);
    }
    return fromSolidity;
}

async function deployHelper () {
    const helper = await (await ethers.getContractFactory('CurveTwocryptoNGHelper')).deploy();
    await helper.waitForDeployment();
    return await helper.getAddress();
}

async function deployRampMock (pool) {
    const mock = await (await ethers.getContractFactory('CurveTwocryptoNGRampMock')).deploy(pool);
    await mock.waitForDeployment();
    return await mock.getAddress();
}

describe('CurveTwocryptoNGHelper', function () {
    after(async function () {
        await resetHardhatNetworkFork(network, 'hardhat');
    });

    // The Solidity port must be a drop-in replacement for the Vyper helper: same selector,
    // same 288-byte response, byte for byte, on every Twocrypto-NG pool.
    describe('Arbitrum: parity with the deployed Vyper helper', function () {
        let solidityHelper;

        before(async function () {
            if (!process.env.ARBITRUM_RPC_URL) this.skip();
            await resetHardhatNetworkFork(network, 'arbitrum');
            solidityHelper = await deployHelper();
        });

        it('keeps the prep_calc(address) selector', async function () {
            const helper = await ethers.getContractAt('CurveTwocryptoNGHelper', solidityHelper);
            expect(helper.interface.getFunction('prep_calc').selector).to.be.equal(PREP_CALC_SELECTOR);
        });

        it('matches the runtime bytecode fixture used by the Polygon tests', async function () {
            expect(await ethers.provider.getCode(VYPER_HELPER)).to.be.equal(vyperRuntime());
        });

        it('returns identical data for the factory pools', async function () {
            const pools = await factoryPools();
            expect(pools.length).to.be.gt(0);
            for (const pool of pools) {
                await expectSameResponse(solidityHelper, pool);
            }
        }).timeout(500000);

        it('returns identical data while A/gamma are ramping', async function () {
            const pools = (await factoryPools()).slice(0, 8);
            let recomputed = 0;
            for (const pool of pools) {
                const ramping = await deployRampMock(pool);
                const ramped = await expectSameResponse(solidityHelper, ramping);
                if (ramped === null) continue;
                // the ramp branch recomputes D through MATH.newton_D, so it must differ from the stored one
                const storedD = ethers.dataSlice(await prepCalc(solidityHelper, pool), 64, 96);
                if (ethers.dataSlice(ramped, 64, 96) !== storedD) recomputed++;
            }
            expect(recomputed, 'newton_D branch never exercised').to.be.greaterThan(0);
        }).timeout(500000);
    });

    // The helper is not deployed on Polygon, so the original runtime bytecode (read from Arbitrum)
    // is injected to compare both implementations on Polygon state.
    describe('Polygon: parity on the frxUSD pools', function () {
        let solidityHelper;

        before(async function () {
            if (!process.env.MATIC_RPC_URL) this.skip();
            await resetHardhatNetworkFork(network, 'matic');
            await network.provider.send('hardhat_setCode', [VYPER_HELPER, vyperRuntime()]);
            solidityHelper = await deployHelper();
        });

        it('returns identical data for the frxUSD pools', async function () {
            for (const pool of POLYGON_FRXUSD_POOLS) {
                await expectSameResponse(solidityHelper, pool.address);
            }
        }).timeout(500000);

        it('returns identical data for the factory pools', async function () {
            const pools = await factoryPools();
            expect(pools.length).to.be.gt(0);
            for (const pool of pools) {
                await expectSameResponse(solidityHelper, pool);
            }
        }).timeout(500000);

        it('returns identical data while A/gamma are ramping', async function () {
            for (const pool of POLYGON_FRXUSD_POOLS) {
                await expectSameResponse(solidityHelper, await deployRampMock(pool.address));
            }
        }).timeout(500000);

        it('reports the pool state expected by the off-chain consumer', async function () {
            const poolAbi = [
                'function A() view returns (uint256)',
                'function D() view returns (uint256)',
                'function balances(uint256) view returns (uint256)',
                'function totalSupply() view returns (uint256)',
                'function price_scale() view returns (uint256)',
                'function precisions() view returns (uint256[2])',
            ];

            for (const { name, address, a } of POLYGON_FRXUSD_POOLS) {
                const pool = new ethers.Contract(address, poolAbi, ethers.provider);
                const helper = await ethers.getContractAt('CurveTwocryptoNGHelper', solidityHelper);
                const [xp, d, tokenSupply, priceScale, poolA, gamma, precisions] = await helper.prep_calc(address);

                expect(xp[0], `${name} xp0`).to.be.equal(await pool.balances(0));
                expect(xp[1], `${name} xp1`).to.be.equal(await pool.balances(1));
                expect(d, `${name} D`).to.be.equal(await pool.D());
                expect(tokenSupply, `${name} totalSupply`).to.be.equal(await pool.totalSupply());
                expect(priceScale, `${name} price_scale`).to.be.equal(await pool.price_scale());
                expect(poolA, `${name} A`).to.be.equal(a);
                expect(gamma > 0n, `${name} gamma`).to.be.equal(true);
                expect(precisions, `${name} precisions`).to.be.deep.equal(await pool.precisions());
            }
        }).timeout(500000);

        it('reverts on a non-pool address the same way as the Vyper helper', async function () {
            const frxUsd = '0x80Eede496655FB9047dd39d9f418d5483ED600df';
            expect(await tryPrepCalc(solidityHelper, frxUsd), 'solidity helper must revert').to.be.equal(null);
            expect(await tryPrepCalc(VYPER_HELPER, frxUsd), 'vyper helper must revert').to.be.equal(null);
        });
    });
});
