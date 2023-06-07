// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract CurveLlammaHelper {
    // concat of [active_band(), min_band(), max_band(), price_oracle(), dynamic_fee(), admin_fee(), p_oracle_up()]
    bytes32 private constant _SELECTORS = 0x8f8654c5ca72a821aaa615fc86fc88d377c34594fee3f7f92eb858e700000000;

    function get(address pool) external view returns(bytes memory) {
        assembly {
            let pos := 0x120
            let ptr := mload(0x40)
            let res := add(ptr, 0x24)
            mstore(res, 0x20)

            mstore(ptr, _SELECTORS)

            // call active_band()
            if iszero(staticcall(gas(), pool, ptr, 0x04, add(res, 0x40), 0x20)) { revert(ptr, 0x04) }

            // copy result to p_oracle_up arg
            mstore(add(ptr, 28), mload(add(res, 0x40)))

            // call p_oracle_up(active_band)
            if iszero(staticcall(gas(), pool, add(ptr, 24), 0x24, add(res, 0x60), 0x20)) { revert(add(ptr, 24), 0x24) }

            // call min_band()
            if iszero(staticcall(gas(), pool, add(ptr, 4), 0x04, add(res, 0x80), 0x20)) { revert(add(ptr, 4), 0x04) }

            let min := mload(add(res, 0x80))

            // call max_band()
            if iszero(staticcall(gas(), pool, add(ptr, 8), 0x04, add(res, 0xA0), 0x20)) { revert(add(ptr, 8), 0x04) }

            let max := mload(add(res, 0xA0))

            // call price_oracle()
            if iszero(staticcall(gas(), pool, add(ptr, 12), 0x04, add(res, 0xC0), 0x20)) { revert(add(ptr, 12), 0x04) }

            // call dynamic_fee()
            if iszero(staticcall(gas(), pool, add(ptr, 16), 0x04, add(res, 0xE0), 0x20)) { revert(add(ptr, 16), 0x04) }

            // call admin_fee()
            if iszero(staticcall(gas(), pool, add(ptr, 20), 0x04, add(res, 0x100), 0x20)) { revert(add(ptr, 20), 0x04) }

            for { let i := min } slt(i, max) { i := add(i, 1) } {
                let c := and(i, 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                let p := pos

                mstore(ptr, shl(224, 0xebcb0067))
                mstore(add(ptr, 4), i)
                // call bands_x(i)
                if iszero(staticcall(gas(), pool, ptr, 0x24, add(res, add(p, 0x20)), 0x20)) { revert(ptr, 0x24) }

                if gt(mload(add(res, add(p, 0x20))), 0) {
                    p := add(p, 0x20)
                    c := or(c, shl(255, 1))
                }

                mstore(ptr, shl(224, 0x31f7e306))
                mstore(add(ptr, 4), i)
                // call bands_y(i)
                if iszero(staticcall(gas(), pool, ptr, 0x24, add(res, add(p, 0x20)), 0x20)) { revert(ptr, 0x24) }

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
