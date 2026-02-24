const { ethers } = require('hardhat');
const { expect } = require('@1inch/solidity-utils');
const { OneTargetPackedCall, OneTargetPackedMulticall } = require('./one-target-multicall');
const { PatchableCall, PatchableMulticall } = require('./patchable-multicall');

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
            const m = OneTargetPackedMulticall.new({ target: targetAddress, calls: [] });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(0);
        });

        it('single successful call: returnWordIndex 0, parses first 32 bytes', async function () {
            const data = target.interface.encodeFunctionData('getUint');
            const m = OneTargetPackedMulticall.new({
                target: targetAddress,
                calls: [OneTargetPackedCall.new({ data, returnWordIndex: 0 })],
            });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(1);
            expect(decoded[0].success).to.equal(true);
            expect(Number(decoded[0].gasUsed)).to.be.gt(0);
            expect(decoded[0].value).to.equal(42n);
        });

        it('single successful call: returnWordIndex 1, parses second 32 bytes', async function () {
            const data = target.interface.encodeFunctionData('getSeveralWords', [1, 2, 3, 4, 5]);
            const m = OneTargetPackedMulticall.new({
                target: targetAddress,
                calls: [OneTargetPackedCall.new({ data, returnWordIndex: 1 })],
            });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(1);
            expect(decoded[0].success).to.equal(true);
            expect(Number(decoded[0].gasUsed)).to.be.gt(0);
            expect(decoded[0].value).to.equal(2n);
        });

        it('failed call: success bit 0, gasUsed set, value 0', async function () {
            const data = target.interface.encodeFunctionData('doRevert');
            const m = OneTargetPackedMulticall.new({
                target: targetAddress,
                calls: [OneTargetPackedCall.new({ data, returnWordIndex: 0 })],
            });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(1);
            expect(decoded[0].success).to.equal(false);
            expect(Number(decoded[0].gasUsed)).to.be.gt(0);
            expect(decoded[0].value).to.equal(0n);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintData = target.interface.encodeFunctionData('getUint');
            const doRevertData = target.interface.encodeFunctionData('doRevert');
            const m = OneTargetPackedMulticall.new({
                target: targetAddress,
                calls: [
                    OneTargetPackedCall.new({ data: getUintData, returnWordIndex: 0 }),
                    OneTargetPackedCall.new({ data: doRevertData, returnWordIndex: 0 }),
                    OneTargetPackedCall.new({ data: getUintData, returnWordIndex: 0 }),
                ],
            });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(3);
            expect(decoded[0].success).to.equal(true);
            expect(decoded[0].value).to.equal(42n);
            expect(decoded[1].success).to.equal(false);
            expect(decoded[1].value).to.equal(0n);
            expect(decoded[2].success).to.equal(true);
            expect(decoded[2].value).to.equal(42n);
        });

        it('100 calls: all successful', async function () {
            const data = target.interface.encodeFunctionData('getUint');
            const calls = Array(100).fill(null).map(() => OneTargetPackedCall.new({ data, returnWordIndex: 0 }));
            const m = OneTargetPackedMulticall.new({ target: targetAddress, calls });
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: m.encode() });
            const decoded = OneTargetPackedMulticall.decode(res);
            expect(decoded).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                expect(decoded[i].success).to.equal(true);
                expect(decoded[i].value).to.equal(42n);
            }
        });
    });

    describe('multicallOneTargetPackedPatchable', function () {
        it('one calldata × one patch value: one call', async function () {
            const baseDataHex = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const call = PatchableCall.new({ returnWordIndex: 0, patchOffset: 4, baseDataHex, patchValues: [1n] });
            const patchableMulticall = PatchableMulticall.new({ target: targetAddress, calls: [call] });
            const res = await multiCall.runner.provider.call({
                to: await multiCall.getAddress(),
                data: patchableMulticall.encode(),
            });
            const decodedResults = PatchableMulticall.decode(res);
            expect(decodedResults).to.have.lengthOf(1);
            expect(decodedResults[0].success).to.equal(true);
            expect(decodedResults[0].outOfRange).to.equal(false);
            expect(decodedResults[0].value).to.equal(1n);
            expect(Number(decodedResults[0].gasUsed)).to.gt(0);
        });

        it('return value out of range', async function () {
            const baseDataHex = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const call = PatchableCall.new({ returnWordIndex: 0, patchOffset: 4, baseDataHex, patchValues: [1n << 226n] });
            const patchableMulticall = PatchableMulticall.new({ target: targetAddress, calls: [call] });
            const res = await multiCall.runner.provider.call({
                to: await multiCall.getAddress(),
                data: patchableMulticall.encode(),
            });
            const decodedResults = PatchableMulticall.decode(res);
            expect(decodedResults).to.have.lengthOf(1);
            expect(decodedResults[0].success).to.equal(true);
            expect(decodedResults[0].outOfRange).to.equal(true);
            expect(decodedResults[0].value).to.equal(0n);
        });

        it('one calldata × 100 patch values: 100 calls', async function () {
            const call = PatchableCall.new({
                returnWordIndex: 0,
                patchOffset: 4,
                baseDataHex: target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]),
                patchValues: Array.from({ length: 100 }, (_, i) => BigInt(i) + 1n, 0n),
            });

            const patchableMulticall = PatchableMulticall.new({
                target: targetAddress,
                calls: [call],
            });

            const res = await multiCall.runner.provider.call({
                to: await multiCall.getAddress(),
                data: patchableMulticall.encode(),
            });

            const decodedResults = PatchableMulticall.decode(res);

            expect(decodedResults).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                const decoded = decodedResults[i];
                expect(decoded.success).to.equal(true);
                expect(decoded.outOfRange).to.equal(false);
                expect(decoded.value).to.equal(BigInt(i + 1));
            }
        });

        it('two calldatas × two patch values each: 4 calls', async function () {
            const baseDataHex = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const calls = [
                PatchableCall.new({ returnWordIndex: 0, patchOffset: 4, baseDataHex, patchValues: [1n, 2n] }),
                PatchableCall.new({ returnWordIndex: 0, patchOffset: 4, baseDataHex, patchValues: [3n, 4n] }),
            ];
            const patchableMulticall = PatchableMulticall.new({ target: targetAddress, calls });
            const res = await multiCall.runner.provider.call({
                to: await multiCall.getAddress(),
                data: patchableMulticall.encode(),
            });
            const decodedResults = PatchableMulticall.decode(res);
            expect(decodedResults).to.have.lengthOf(4);
            expect(decodedResults[0].value).to.equal(1n);
            expect(decodedResults[1].value).to.equal(2n);
            expect(decodedResults[2].value).to.equal(3n);
            expect(decodedResults[3].value).to.equal(4n);
        });
    });

    describe('multicallWithGas', function () {
        it('returns empty array when numCalls is 0', async function () {
            const data = multiCall.interface.encodeFunctionData('multicallWithGas', [[]]);
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data });
            const [results, gasUsed] = multiCall.interface.decodeFunctionResult('multicallWithGas', res);
            expect(results).to.have.lengthOf(0);
            expect(gasUsed).to.have.lengthOf(0);
        });

        it('single successful call', async function () {
            const data = multiCall.interface.encodeFunctionData('multicallWithGas', [[{
                to: targetAddress,
                data: target.interface.encodeFunctionData('getUint'),
            }]]);
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data });
            const [results, gasUsed] = multiCall.interface.decodeFunctionResult('multicallWithGas', res);
            expect(results).to.have.lengthOf(1);
            expect(BigInt(results[0])).to.equal(42n);
            expect(Number(gasUsed[0])).to.be.gt(0);
        });

        it('failed call', async function () {
            const data = multiCall.interface.encodeFunctionData('multicallWithGas', [[{
                to: targetAddress,
                data: target.interface.encodeFunctionData('doRevert'),
            }]]);
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data });
            const [results, gasUsed] = multiCall.interface.decodeFunctionResult('multicallWithGas', res);
            expect(results).to.have.lengthOf(1);
            expect(Number(gasUsed[0])).to.be.gt(0);
        });

        it('multiple calls: mix success and failure', async function () {
            const getUintData = target.interface.encodeFunctionData('getUint');
            const doRevertData = target.interface.encodeFunctionData('doRevert');

            const data = multiCall.interface.encodeFunctionData('multicallWithGas', [[
                {
                    to: targetAddress,
                    data: getUintData,
                },
                {
                    to: targetAddress,
                    data: doRevertData,
                },
                {
                    to: targetAddress,
                    data: getUintData,
                },
            ]]);
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data });
            const [results, gasUsed] = multiCall.interface.decodeFunctionResult('multicallWithGas', res);

            expect(results).to.have.lengthOf(3);
            expect(BigInt(results[0])).to.equal(42n);
            expect(Number(gasUsed[1])).to.be.gt(0);
            expect(BigInt(results[2])).to.equal(42n);
        });

        it('100 calls: all successful', async function () {
            const getUintData = target.interface.encodeFunctionData('getUint');
            const calls = Array.from({ length: 100 }).map(() => ({
                to: targetAddress,
                data: getUintData,
            }));
            const data = multiCall.interface.encodeFunctionData('multicallWithGas', [calls]);
            const res = await multiCall.runner.provider.call({ to: await multiCall.getAddress(), data });
            const [results] = multiCall.interface.decodeFunctionResult('multicallWithGas', res);
            expect(results).to.have.lengthOf(100);
            for (let i = 0; i < 100; i++) {
                expect(BigInt(results[i])).to.equal(42n);
            }
        });
    });

    describe.skip('performance', function () {
        it('getSeveralWords', async function () {
            const baseDataHex = target.interface.encodeFunctionData('getSeveralWords', [0, 0, 0, 0, 0]);
            const patchableCalls = [
                PatchableCall.new({
                    returnWordIndex: 0,
                    patchOffset: 4,
                    baseDataHex,
                    patchValues: Array.from({ length: 100 }, (_, i) => BigInt(i) + 1n),
                }),
            ];
            const packedCalls = Array.from({ length: 100 }, (_, i) =>
                OneTargetPackedCall.new({
                    data: target.interface.encodeFunctionData('getSeveralWords', [BigInt(i) + 1n, 0, 0, 0, 0]),
                    returnWordIndex: 0,
                }),
            );
            const withGasCalls = Array.from({ length: 100 }, (_, i) => (
                {
                    to: targetAddress,
                    data: target.interface.encodeFunctionData('getSeveralWords', [BigInt(i) + 1n, 0, 0, 0, 0]),
                }
            ));

            const multiCallAddress = await multiCall.getAddress();
            const patchableGas = await multiCall.runner.provider.estimateGas({
                to: multiCallAddress,
                data: PatchableMulticall.new({ target: targetAddress, calls: patchableCalls }).encode(),
            });
            const packedGas = await multiCall.runner.provider.estimateGas({
                to: multiCallAddress,
                data: OneTargetPackedMulticall.new({ target: targetAddress, calls: packedCalls }).encode(),
            });
            const withGasGas = await multiCall.runner.provider.estimateGas({
                to: multiCallAddress,
                data: multiCall.interface.encodeFunctionData('multicallWithGas', [withGasCalls]),
            });

            expect(Number(withGasGas)).to.be.eq(454_751);
            expect(Number(packedGas)).to.be.eq(180_803);
            expect(Number(patchableGas)).to.be.eq(102_786);
        });
    });
});
