// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IUniswapV3.sol";

contract SolidlyV3Helper {
    error ZeroInputError();

    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    function getTicks(IUniswapV3 pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        (,int24 tick) = pool.slot0();

        int24 fromTick = tick - (tickSpacing * tickRange);
        int24 toTick = tick + (tickSpacing * tickRange);
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256(toTick - fromTick + 1) / int256(tickSpacing)));

        uint counter = 0;
        for (int24 tickNum = (fromTick / tickSpacing * tickSpacing); tickNum <= (toTick / tickSpacing * tickSpacing); tickNum += (256 * tickSpacing)) {
            int16 pos = int16((tickNum / tickSpacing) >> 8);
            uint256 bm = pool.tickBitmap(pos);

            while (bm != 0) {
                uint8 bit = _mostSignificantBit(bm);
                initTicks[counter] = (int24(pos) * 256 + int24(int256(uint256(bit)))) * tickSpacing;
                counter += 1;
                bm ^= 1 << bit;
            }
        }

        ticks = new bytes[](counter);
        for (uint i = 0; i < counter; i++) {
             ticks[i] = abi.encodePacked(initTicks[i]);
        }
    }

    function _mostSignificantBit(uint256 x) private pure returns (uint8 r) {
        if (x == 0) revert ZeroInputError();

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}
