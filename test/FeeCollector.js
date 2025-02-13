const { ethers } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');

const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const LOP = '0x111111125421cA6dc452d289314280a0f8842A65';

describe('FeeCollector', function () {
    it('arbitrary call should work', async function () {
        const [alice] = await ethers.getSigners();

        const feeCollectorImpl = await (await ethers.getContractFactory('FeeCollector')).deploy(WETH, LOP, alice);
        await feeCollectorImpl.waitForDeployment();

        const feeCollectorFactory = await (await ethers.getContractFactory('FeeCollectorFactory')).deploy(await feeCollectorImpl.getAddress(), alice);
        await feeCollectorFactory.waitForDeployment();

        const salt = ethers.keccak256(ethers.toUtf8Bytes('TestFeeCollector'));

        await feeCollectorFactory.deployFeeCollector(salt);
        const feeCollectorAddr = await feeCollectorFactory.getFeeCollectorAddress(salt);
        
        const value = 10000000n;

        await alice.sendTransaction({ to: feeCollectorAddr, value });

        expect(await ethers.provider.getBalance(feeCollectorAddr)).to.eq(value);

        const feeCollector = await (await ethers.getContractFactory('FeeCollector')).attach(feeCollectorAddr);

        await feeCollector.setOperator(alice)
        await feeCollector.rescueEther();

        expect(await ethers.provider.getBalance(feeCollectorAddr)).to.eq(0n);
    });
});
