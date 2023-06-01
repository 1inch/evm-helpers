pragma solidity 0.8.19;

contract CurveLlammaHelper {
    function get(address pool) public view returns(bytes memory) {
        int256 m = type(int256).min;

        assembly {
            let pos := 0x120
            let min
            let max
            let in := mload(0x40)
            let res := add(in, 0x24)
            mstore(res, 0x20)

            mstore(in, shl(224, 0x8f8654c5)) // active_band()
            let success := staticcall(50000, pool, in, 0x04, add(res, 0x40), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }

            mstore(in, shl(224, 0x2eb858e7)) // p_oracle_up(int256)
            mstore(add(in, 4), mload(add(res, 0x40)))
            success := staticcall(50000, pool, in, 0x24, add(res, 0x60), 0x20)
            if eq(success, 0) {
                revert(in, 0x24)
            }

            mstore(in, shl(224, 0xca72a821)) // min_band()
            success := staticcall(50000, pool, in, 0x04, add(res, 0x80), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }
            min := mload(add(res, 0x80))

            mstore(in, shl(224, 0xaaa615fc)) // max_band()
            success := staticcall(50000, pool, in, 0x04, add(res, 0xA0), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }
            max := mload(add(res, 0xA0))

            mstore(in, shl(224, 0x86fc88d3)) // price_oracle()
            success := staticcall(500000, pool, in, 0x04, add(res, 0xC0), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }

            mstore(in, shl(224, 0x77c34594)) // dynamic_fee()
            success := staticcall(500000, pool, in, 0x04, add(res, 0xE0), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }

            mstore(in, shl(224, 0xfee3f7f9)) // admin_fee()
            success := staticcall(50000, pool, in, 0x04, add(res, 0x100), 0x20)
            if eq(success, 0) {
                revert(in, 0x04)
            }

            for { let i := min } or(gt(i, m), lt(i, max)) { i := add(i, 1) } {
                let c := and(i, 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                let p := pos

                mstore(in, shl(224, 0xebcb0067)) // bands_x(int256)
                mstore(add(in, 4), i)
                success := staticcall(50000, pool, in, 0x24, add(res, add(p, 0x20)), 0x20)
                if eq(success, 0) {
                    revert(in, 0x24)
                }
                if gt(mload(add(res, add(p, 0x20))), 0) {
                    p := add(p, 0x20)
                    c := or(c, shl(255, 1))
                }

                mstore(in, shl(224, 0x31f7e306)) // bands_y(int256)
                mstore(add(in, 4), i)
                success := staticcall(50000, pool, in, 0x24, add(res, add(p, 0x20)), 0x20)
                if eq(success, 0) {
                    revert(in, 0x24)
                }
                if gt(mload(add(res, add(p, 0x20))), 0) {
                    p := add(p, 0x20)
                    c := or(c, shl(254, 1))
                }

                if gt(p, pos) {
                    mstore(add(res, pos), c)
                    pos := add(p, 0x20)
                }
            }
            mstore(add(res, 0x20), sub(pos, 0x40))
            return (res, pos)
        }
    }
}
