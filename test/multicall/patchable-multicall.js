const { bytesToHex, hexToBytes, toHex } = require('./utils');

class PatchableCall {
    static DATA_LENGTH_MASK = (1n << 200n) - 1n;

    constructor (returnWordIndex, patchOffset, baseDataHex, patchValues) {
        this.returnWordIndex = returnWordIndex;
        this.patchOffset = patchOffset;
        this.baseDataHex = baseDataHex;
        this.patchValues = patchValues;
    }

    static new (params) {
        return new PatchableCall(
            params.returnWordIndex,
            params.patchOffset,
            params.baseDataHex,
            params.patchValues,
        );
    }

    get patchValuesCount () {
        return this.patchValues.length;
    }

    get baseDataBytes () {
        const h = this.baseDataHex.startsWith('0x') ? this.baseDataHex.slice(2) : this.baseDataHex;
        return Math.floor(h.length / 2);
    }

    encode () {
        const dataLength = this.baseDataBytes;
        const numPatches = this.patchValues.length;
        const header =
            (BigInt(this.returnWordIndex) << 248n) |
            (BigInt(numPatches) << 232n) |
            (BigInt(this.patchOffset) << 216n) |
            (BigInt(dataLength) & PatchableCall.DATA_LENGTH_MASK);

        let baseHex = this.baseDataHex.startsWith('0x') ? this.baseDataHex.slice(2) : this.baseDataHex;
        if (baseHex.length % 2) {
            baseHex = '0' + baseHex;
        }

        const parts = [toHex(header, 32), '0x' + baseHex];
        for (const v of this.patchValues) {
            parts.push(toHex(BigInt(v), 32));
        }
        return parts;
    }
}

class PatchableMulticall {
    static SELECTOR = '0x7bc97c36'; // keccak256('multicallOneTargetPackedPatchable()').slice(0, 10)

    constructor (target, calls) {
        this.target = target;
        this.calls = calls;
    }

    static new (params) {
        return new PatchableMulticall(params.target, params.calls);
    }

    static decode (res) {
        const bytes = hexToBytes(res);
        if (bytes.length < 64) {
            return [];
        }
        const lengthWord = bytes.slice(32, 64);

        let len = 0;
        for (let i = 0; i < 32; i++) {
            len = (len << 8) | lengthWord[i];
        }

        const data = bytes.slice(64, 64 + len);
        const count = Math.floor(data.length / 32);

        const results = [];
        for (let i = 0; i < count; i++) {
            let word = 0n;
            for (let j = 0; j < 32; j++) {
                word = (word << 8n) | BigInt(data[i * 32 + j]);
            }
            results.push(PackedResult.decode(word));
        }
        return results;
    }

    encode () {
        const numCalls = this.calls.reduce((s, e) => s + e.patchValuesCount, 0);

        const chunks = [
            hexToBytes(PatchableMulticall.SELECTOR),
            hexToBytes(toHex(numCalls, 2)),
            hexToBytes(toHex(this.calls.length, 2)),
            hexToBytes(this.target.replace('0x', '')),
        ];

        for (const entry of this.calls) {
            const parts = entry.encode();
            for (const p of parts) {
                chunks.push(hexToBytes(p));
            }
        }

        const total = chunks.reduce((s, c) => s + c.length, 0);
        const out = new Uint8Array(total);
        let offset = 0;
        for (const c of chunks) {
            out.set(c, offset);
            offset += c.length;
        }
        return bytesToHex(out);
    }
}

class PackedResult {
    static GAS_USED_MASK = (1n << 254n) - (1n << 226n);
    static VALUE_MASK = (1n << 226n) - 1n;

    constructor (success, outOfRange, gasUsed, value) {
        this.success = success;
        this.outOfRange = outOfRange;
        this.gasUsed = gasUsed;
        this.value = value;
    }

    static decode (packed) {
        const r = BigInt(packed);
        return new PackedResult(
            ((r >> 255n) & 1n) !== 0n,
            ((r >> 254n) & 1n) !== 0n,
            (r & PackedResult.GAS_USED_MASK) >> 226n,
            r & PackedResult.VALUE_MASK,
        );
    }
}

module.exports = {
    PatchableMulticall,
    PatchableCall,
};
