const { bytesToHex, hexToBytes, toHex } = require('./utils');

class OneTargetPackedCall {
    constructor (returnWordIndex, data) {
        this.returnWordIndex = returnWordIndex;
        this.data = data;
    }

    static new (params) {
        return new OneTargetPackedCall(params.returnWordIndex, params.data);
    }

    get dataBytes () {
        const h = this.data.startsWith('0x') ? this.data.slice(2) : this.data;
        return Math.floor(h.length / 2);
    }

    encode () {
        const dataLength = this.dataBytes;
        const header = (BigInt(this.returnWordIndex) << 248n) | BigInt(dataLength);
        let data = this.data.startsWith('0x') ? this.data.slice(2) : this.data;
        if (data.length % 2) {
            data = '0' + data;
        }
        return [toHex(header, 32), '0x' + data];
    }
}

class OneTargetPackedMulticall {
    static SELECTOR = '0x27ae9ae3'; // keccak256('multicallOneTargetPacked()').slice(0,10)

    constructor (target, calls) {
        this.target = target;
        this.calls = calls;
    }

    static new (params) {
        return new OneTargetPackedMulticall(params.target, params.calls);
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
        const chunks = [
            hexToBytes(OneTargetPackedMulticall.SELECTOR),
            hexToBytes(toHex(this.calls.length, 2)),
            hexToBytes(this.target.replace(/^0x/, '').toLowerCase().padStart(40, '0')),
        ];

        for (const call of this.calls) {
            for (const chunk of call.encode()) {
                chunks.push(hexToBytes(chunk));
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
    OneTargetPackedMulticall,
    OneTargetPackedCall,
    PackedResult,
};
