const { ethers } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const {
    unpackResult,
    callMulticallOneTargetPackedAndMeasureGas,
    callMulticallWithGasAndMeasureGas,
} = require('./utils');

describe('MultiCall', function () {
    let multiCall;
    let target;
    let targetAddress;

    before(async function () {
        multiCall = await (await ethers.getContractFactory('MultiCall')).deploy();
        await multiCall.waitForDeployment();
        target = await (await ethers.getContractFactory('MultiCallTestTarget')).deploy();
        await target.waitForDeployment();
        targetAddress = await target.getAddress()
    });

    describe('multicallOneTargetPacked', function () {

        it('returns empty array when numCalls is 0', async function () {
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, await target.getAddress(), []);
            expect(decodedArray).to.have.lengthOf(0);
            expect(estimatedGas).to.be.lte(21656);
            expect(estimatedGas - totalPerCallGas).to.be.lte(21656);
        });

        it('single successful call: returnWordIndex 0, parses first 32 bytes', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(
                multiCall,
                await target.getAddress(),
                [{ data: getUintCalldata, returnWordIndex: 0 }]
            );
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(42n);
            expect(estimatedGas).to.be.lte(25264);
            expect(estimatedGas - totalPerCallGas).to.be.lte(22499);
        });

        it('single successful call: returnWordIndex 1, parses second 32 bytes', async function () {
            const getSeveralWordsCalldata = target.interface.encodeFunctionData('getSeveralWords', [1, 2, 3, 4, 5]);
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, await target.getAddress(), [{ data: getSeveralWordsCalldata, returnWordIndex: 1 }]);
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(2n);
            expect(estimatedGas).to.be.lte(26124);
            expect(estimatedGas - totalPerCallGas).to.be.lte(23244);
        });

        it('failed call: success bit 0, gasUsed set, value 0', async function () {
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, await target.getAddress(), [{ data: doRevertCalldata, returnWordIndex: 0 }]);
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(false);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(0n);
            expect(estimatedGas).to.be.lte(25283);
            expect(estimatedGas - totalPerCallGas).to.be.lte(22472);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, await target.getAddress(), [
                { data: getUintCalldata, returnWordIndex: 0 },
                { data: doRevertCalldata, returnWordIndex: 0 },
                { data: getUintCalldata, returnWordIndex: 0 },
            ]);
            expect(decodedArray).to.have.lengthOf(3);
            const r0 = unpackResult(decodedArray[0]);
            const r1 = unpackResult(decodedArray[1]);
            const r2 = unpackResult(decodedArray[2]);
            expect(r0.success).to.equal(true);
            expect(r0.value).to.equal(42n);
            expect(r1.success).to.equal(false);
            expect(r1.value).to.equal(0n);
            expect(r2.success).to.equal(true);
            expect(r2.value).to.equal(42n);
            expect(estimatedGas).to.be.lte(26935);
            expect(estimatedGas - totalPerCallGas).to.be.lte(23594);
        });

        it('5 calls: all successful', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const calls = Array(5).fill({ data: getUintCalldata, returnWordIndex: 0 });
            const { decodedArray, estimatedGas, totalPerCallGas } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, await target.getAddress(), calls);
            expect(decodedArray).to.have.lengthOf(5);
            for (let i = 0; i < 5; i++) {
                const { success, value } = unpackResult(decodedArray[i]);
                expect(success).to.equal(true);
                expect(value).to.equal(42n);
            }
            expect(estimatedGas).to.be.lte(28568);
            expect(estimatedGas - totalPerCallGas).to.be.lte(24743);
        });
    });

    describe('multicallWithGas', function () {
        function toCall(data) {
            return { to: targetAddress, data };
        }

        it('returns empty array when numCalls is 0', async function () {
            const { results, gasUsed, estimatedGas, totalPerCallGas } = await callMulticallWithGasAndMeasureGas(multiCall, []);
            expect(results).to.have.lengthOf(0);
            expect(gasUsed).to.have.lengthOf(0);
            expect(estimatedGas).to.be.lte(22908);
            expect(estimatedGas - totalPerCallGas).to.be.lte(22908);
        });

        it('single successful call', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');

            const calls = [toCall(getUintCalldata)];
            const { results, gasUsed, estimatedGas, totalPerCallGas } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(1);
            expect(BigInt(results[0])).to.equal(42n);
            expect(gasUsed[0]).to.be.gt(0);
            expect(estimatedGas).to.be.lte(28509);
            expect(estimatedGas - totalPerCallGas).to.be.lte(25205);
        });

        it('failed call', async function () {
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const calls = [toCall(doRevertCalldata)];
            const { results, gasUsed, estimatedGas, totalPerCallGas } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(1);
            expect(gasUsed[0]).to.be.gt(0);
            expect(estimatedGas).to.be.lte(28567);
            expect(estimatedGas - totalPerCallGas).to.be.lte(25217);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const calls = [
                toCall(getUintCalldata),
                toCall(doRevertCalldata),
                toCall(getUintCalldata),
            ];
            const { results, gasUsed, estimatedGas, totalPerCallGas } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(3);
            expect(BigInt(results[0])).to.equal(42n);
            expect(gasUsed[1]).to.be.gt(0);
            expect(BigInt(results[2])).to.equal(42n);
            expect(estimatedGas).to.be.lte(34758);
            expect(estimatedGas - totalPerCallGas).to.be.lte(29799);
        });

        it('5 calls: all successful', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const calls = Array(5).fill(null).map(() => toCall(getUintCalldata));
            const { results, estimatedGas, totalPerCallGas } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(5);
            for (let i = 0; i < 5; i++) {
                expect(BigInt(results[i])).to.equal(42n);
            }
            expect(estimatedGas).to.be.lte(40919);
            expect(estimatedGas - totalPerCallGas).to.be.lte(34397);
        });
    });
});
