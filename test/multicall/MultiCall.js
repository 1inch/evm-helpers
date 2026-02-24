const { ethers } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const {
    unpackResult,
    buildMulticallOneTargetPackedPatchableCalldata,
    callMulticallOneTargetPackedAndMeasureGas,
    callMulticallOneTargetPackedPatchableAndMeasureGas,
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
        targetAddress = await target.getAddress();
    });

    describe('multicallOneTargetPacked', function () {
        it('returns empty array when numCalls is 0', async function () {
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, targetAddress, []);
            expect(decodedArray).to.have.lengthOf(0);
        });

        it('single successful call: returnWordIndex 0, parses first 32 bytes', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(
                multiCall,
                targetAddress,
                [{ data: getUintCalldata, returnWordIndex: 0 }],
            );
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(42n);
        });

        it('single successful call: returnWordIndex 1, parses second 32 bytes', async function () {
            const getSeveralWordsCalldata = target.interface.encodeFunctionData('getSeveralWords', [1, 2, 3, 4, 5]);
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(
                multiCall,
                targetAddress,
                [{ data: getSeveralWordsCalldata, returnWordIndex: 1 }],
            );
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(2n);
        });

        it('failed call: success bit 0, gasUsed set, value 0', async function () {
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(
                multiCall,
                targetAddress,
                [{ data: doRevertCalldata, returnWordIndex: 0 }],
            );
            expect(decodedArray).to.have.lengthOf(1);
            const { success, gasUsed, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(false);
            expect(gasUsed).to.be.gt(0);
            expect(value).to.equal(0n);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, targetAddress, [
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
        });

        it('100 calls: all successful', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const calls = Array(100).fill({ data: getUintCalldata, returnWordIndex: 0 });
            const { decodedArray } = await callMulticallOneTargetPackedAndMeasureGas(multiCall, targetAddress, calls);
            expect(decodedArray).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                const { success, value } = unpackResult(decodedArray[i]);
                expect(success).to.equal(true);
                expect(value).to.equal(42n);
            }
        });
    });

    describe('multicallOneTargetPackedPatchable', function () {
        it('one calldata × one patch value: one call', async function () {
            const baseData = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const calls = [{ baseData, returnWordIndex: 0, patchOffset: 4, patchValues: [1n] }];
            const { decodedArray } = await callMulticallOneTargetPackedPatchableAndMeasureGas(multiCall, targetAddress, calls);
            expect(decodedArray).to.have.lengthOf(1);
            const { success, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(value).to.equal(1n);
        });

        it('return value out of range', async function () {
            const baseData = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const calls = [{ baseData, returnWordIndex: 0, patchOffset: 4, patchValues: [1n << 226n] }];
            const { decodedArray } = await callMulticallOneTargetPackedPatchableAndMeasureGas(multiCall, targetAddress, calls);
            expect(decodedArray).to.have.lengthOf(1);
            const { success, outOfRange, value } = unpackResult(decodedArray[0]);
            expect(success).to.equal(true);
            expect(outOfRange).to.equal(true);
            expect(value).to.equal(0n);
        });

        it('one calldata × 100 patch values: 100 calls', async function () {
            const baseData = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const patchValues = Array.from({ length: 100 }, (_, i) => BigInt(i) + 1n, 0n);
            const calls = [{ baseData, returnWordIndex: 0, patchOffset: 4, patchValues }];
            const { decodedArray } = await callMulticallOneTargetPackedPatchableAndMeasureGas(multiCall, targetAddress, calls);
            expect(decodedArray).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                const { success, value } = unpackResult(decodedArray[i]);
                expect(success).to.equal(true);
                expect(value).to.equal(BigInt(i + 1));
            }
        });

        it('two calldatas × two patch values each: 4 calls', async function () {
            const baseData = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const calls = [
                { baseData, returnWordIndex: 0, patchOffset: 4, patchValues: [1n, 2n] },
                { baseData, returnWordIndex: 0, patchOffset: 4, patchValues: [3n, 4n] },
            ];
            const data = buildMulticallOneTargetPackedPatchableCalldata(targetAddress, calls);
            expect(ethers.getBytes(data).length).to.equal(548); // 28 + 2*(32+164+64)
            const { decodedArray } = await callMulticallOneTargetPackedPatchableAndMeasureGas(multiCall, targetAddress, calls);
            expect(decodedArray).to.have.lengthOf(4);
            expect(unpackResult(decodedArray[0]).value).to.equal(1n);
            expect(unpackResult(decodedArray[1]).value).to.equal(2n);
            expect(unpackResult(decodedArray[2]).value).to.equal(3n);
            expect(unpackResult(decodedArray[3]).value).to.equal(4n);
        });
    });

    describe('multicallWithGas', function () {
        function toCall (data) {
            return { to: targetAddress, data };
        }

        it('returns empty array when numCalls is 0', async function () {
            const { results, gasUsed } = await callMulticallWithGasAndMeasureGas(multiCall, []);
            expect(results).to.have.lengthOf(0);
            expect(gasUsed).to.have.lengthOf(0);
        });

        it('single successful call', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');

            const calls = [toCall(getUintCalldata)];
            const { results, gasUsed } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(1);
            expect(BigInt(results[0])).to.equal(42n);
            expect(gasUsed[0]).to.be.gt(0);
        });

        it('failed call', async function () {
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const calls = [toCall(doRevertCalldata)];
            const { results, gasUsed } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(1);
            expect(gasUsed[0]).to.be.gt(0);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const doRevertCalldata = target.interface.encodeFunctionData('doRevert');
            const calls = [
                toCall(getUintCalldata),
                toCall(doRevertCalldata),
                toCall(getUintCalldata),
            ];
            const { results, gasUsed } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(3);
            expect(BigInt(results[0])).to.equal(42n);
            expect(gasUsed[1]).to.be.gt(0);
            expect(BigInt(results[2])).to.equal(42n);
        });

        it('100 calls: all successful', async function () {
            const getUintCalldata = target.interface.encodeFunctionData('getUint');
            const calls = Array(100).fill(null).map(() => toCall(getUintCalldata));
            const { results } = await callMulticallWithGasAndMeasureGas(multiCall, calls);
            expect(results).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                expect(BigInt(results[i])).to.equal(42n);
            }
        });
    });

    describe.skip('performance', function () {
        it('getSeveralWords', async function () {
            const calls = [{
                baseData: target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]),
                returnWordIndex: 0,
                patchOffset: 4,
                patchValues: Array.from({ length: 100 }, (_, i) => BigInt(i) + 1n),
            },
            ];

            const calls2 = Array.from({ length: 100 }, (_, i) => ({
                data: target.interface.encodeFunctionData('getSeveralWords', [BigInt(i) + 1n, 0, 0, 0, 0]),
                returnWordIndex: 0,
            }));

            const calls3 = Array.from({ length: 100 }, (_, i) => ({
                data: target.interface.encodeFunctionData('getSeveralWords', [BigInt(i) + 1n, 0, 0, 0, 0]),
                to: targetAddress,
            }));

            const multiCallOneTargetPackedPatchableResult = await callMulticallOneTargetPackedPatchableAndMeasureGas(multiCall, targetAddress, calls);
            const multiCallOneTargetPackedResult = await callMulticallOneTargetPackedAndMeasureGas(multiCall, targetAddress, calls2);
            const multicallWithGasResult = await callMulticallWithGasAndMeasureGas(multiCall, calls3);

            expect(multicallWithGasResult.estimatedGas).to.be.eq(454_751);
            expect(multiCallOneTargetPackedResult.estimatedGas).to.be.eq(180_803);
            expect(multiCallOneTargetPackedPatchableResult.estimatedGas).to.be.eq(102_786);
        });
    });
});
