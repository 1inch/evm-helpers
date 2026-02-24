const { ethers } = require('hardhat');

// Packed result: bit 255 = success, bit 254 = outOfRange, bits 253-226 = gasUsed (28 bits), bits 225-0 = value (226 bits)
const GAS_USED_MASK = (1n << 254n) - (1n << 226n); // bits 253-226 (28 bits)
const VALUE_MASK = (1n << 226n) - 1n; // bits 225-0 (226 bits)

function unpackResult (r) {
    const success = ((r >> 255n) & 1n) !== 0n;
    const outOfRange = ((r >> 254n) & 1n) !== 0n;
    const gasUsed = Number((r & GAS_USED_MASK) >> 226n);
    const value = r & VALUE_MASK;
    return { success, outOfRange, gasUsed, value };
}

function decodeBytesToPackedUint256Array (callResultHex) {
    if (!callResultHex || callResultHex === '0x') return [];
    const bytesHex = ethers.AbiCoder.defaultAbiCoder().decode(['bytes'], callResultHex)[0];
    if (!bytesHex || bytesHex === '0x') return [];
    const data = ethers.getBytes(bytesHex);
    const count = Math.floor(data.length / 32);
    const arr = [];
    for (let i = 0; i < count; i++) {
        const chunk = data.slice(i * 32, (i + 1) * 32);
        arr.push(chunk.length === 0 ? 0n : ethers.toBigInt(ethers.hexlify(chunk)));
    }
    return arr;
}

// Build raw calldata for multicallOneTargetPacked: selector + numCalls(2) + target(20) + [header(32) + data]*
// Header = 32-byte word: highest byte = returnWordIndex, lower 31 bytes = dataLength. Each call is { data: hexString, returnWordIndex: number }.
function buildMulticallOneTargetPackedCalldata (targetAddress, calls) {
    const selector = ethers.id('multicallOneTargetPacked()').slice(0, 10);
    const numCallsBytes = '0x' + calls.length.toString(16).padStart(4, '0');
    const target20 = ethers.zeroPadValue(ethers.getAddress(targetAddress), 20);

    const parts = [
        selector,
        numCallsBytes,
        target20,
    ];

    for (const { data: callData, returnWordIndex } of calls) {
        const lenBytes = ethers.getBytes(callData).length;
        const header = (BigInt(returnWordIndex) << 248n) | BigInt(lenBytes);
        parts.push(ethers.toBeHex(header, 32));
        parts.push(callData);
    }

    return ethers.concat(parts);
}

// Call multicallOneTargetPacked and return decoded results plus gas metrics (estimated gas, per-call gas from packed results).
// calls: array of { data: hexString, returnWordIndex: number }.
async function callMulticallOneTargetPackedAndMeasureGas (multiCall, targetAddress, calls) {
    const data = buildMulticallOneTargetPackedCalldata(targetAddress, calls);
    const [result, estimatedGas] = await Promise.all([
        multiCall.runner.provider.call({ to: await multiCall.getAddress(), data }),
        multiCall.runner.provider.estimateGas({ to: await multiCall.getAddress(), data }),
    ]);
    const decodedArray = decodeBytesToPackedUint256Array(result);
    const perCallGas = decodedArray.map((r) => unpackResult(r).gasUsed);
    const totalPerCallGas = perCallGas.reduce((s, g) => s + g, 0);
    return { decodedArray, estimatedGas: Number(estimatedGas), perCallGas, totalPerCallGas };
}

// Build raw calldata for multicallOneTargetPackedPatchable. Layout: numCalls(2) numCalldatas(2) target(20) then per calldata: header(32) data(N) patchValues(numPatches×32).
// Each call is { baseData, returnWordIndex, patchOffset, patchValues: [bigint|hex,...] }. numCalls = sum of patchValues.length.
function buildMulticallOneTargetPackedPatchableCalldata (targetAddress, calls) {
    const selector = ethers.id('multicallOneTargetPackedPatchable()').slice(0, 10);
    const numCalls = calls.reduce((s, c) => s + c.patchValues.length, 0);
    const numCalldatas = calls.length;
    const numCallsBytes = '0x' + numCalls.toString(16).padStart(4, '0');
    const numCalldatasBytes = '0x' + numCalldatas.toString(16).padStart(4, '0');
    const target20 = ethers.zeroPadValue(ethers.getAddress(targetAddress), 20);

    const parts = [selector, numCallsBytes, numCalldatasBytes, target20];

    for (const { baseData, returnWordIndex, patchOffset, patchValues } of calls) {
        const dataLength = ethers.getBytes(baseData).length;
        const numPatches = patchValues.length;
        const header = (BigInt(returnWordIndex) << 248n) | (BigInt(numPatches) << 232n) | (BigInt(patchOffset) << 216n) | BigInt(dataLength);
        parts.push(ethers.toBeHex(header, 32));
        parts.push(baseData);
        for (const v of patchValues) {
            parts.push(ethers.toBeHex(typeof v === 'bigint' ? v : BigInt(v), 32));
        }
    }

    return ethers.concat(parts);
}

// Call multicallOneTargetPackedPatchable and return decoded results plus gas metrics. calls: array of { baseData, returnWordIndex, patchOffset, patchValues }.
async function callMulticallOneTargetPackedPatchableAndMeasureGas (multiCall, targetAddress, calls) {
    const data = buildMulticallOneTargetPackedPatchableCalldata(targetAddress, calls);
    const [result, estimatedGas] = await Promise.all([
        multiCall.runner.provider.call({ to: await multiCall.getAddress(), data }),
        multiCall.runner.provider.estimateGas({ to: await multiCall.getAddress(), data }),
    ]);
    const decodedArray = decodeBytesToPackedUint256Array(result);
    const perCallGas = decodedArray.map((r) => unpackResult(r).gasUsed);
    const totalPerCallGas = perCallGas.reduce((s, g) => s + g, 0);
    return { decodedArray, estimatedGas: Number(estimatedGas), perCallGas, totalPerCallGas };
}

// Call multicallWithGas and return results, gasUsed, estimatedGas, and sum(gasUsed). calls: array of { to: address, data: hexString }.
async function callMulticallWithGasAndMeasureGas (multiCall, calls) {
    const calldata = multiCall.interface.encodeFunctionData('multicallWithGas', [calls]);
    const [result, estimatedGas] = await Promise.all([
        multiCall.runner.provider.call({ to: await multiCall.getAddress(), data: calldata }),
        multiCall.runner.provider.estimateGas({ to: await multiCall.getAddress(), data: calldata }),
    ]);
    const [results, gasUsed] = multiCall.interface.decodeFunctionResult('multicallWithGas', result);
    const totalPerCallGas = gasUsed.reduce((s, g) => s + Number(g), 0);
    return { results, gasUsed: gasUsed.map(Number), estimatedGas: Number(estimatedGas), totalPerCallGas };
}

module.exports = {
    GAS_USED_MASK,
    VALUE_MASK,
    unpackResult,
    decodeBytesToPackedUint256Array,
    buildMulticallOneTargetPackedCalldata,
    callMulticallOneTargetPackedAndMeasureGas,
    buildMulticallOneTargetPackedPatchableCalldata,
    callMulticallOneTargetPackedPatchableAndMeasureGas,
    callMulticallWithGasAndMeasureGas,
};
