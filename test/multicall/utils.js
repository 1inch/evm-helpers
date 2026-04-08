function toHex (n, byteLength) {
    const hex = BigInt(n).toString(16);
    return '0x' + hex.padStart(byteLength * 2, '0').slice(-byteLength * 2);
}

function hexToBytes (hex) {
    const h = hex.startsWith('0x') ? hex.slice(2) : hex;
    const len = h.length / 2;
    const out = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
        out[i] = parseInt(h.slice(i * 2, i * 2 + 2), 16);
    }
    return out;
}

function bytesToHex (bytes) {
    let s = '';
    for (let i = 0; i < bytes.length; i++) {
        s += bytes[i].toString(16).padStart(2, '0');
    }
    return '0x' + s;
}

module.exports = {
    toHex,
    hexToBytes,
    bytesToHex,
};
