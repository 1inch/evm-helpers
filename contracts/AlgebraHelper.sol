// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IAlgebra.sol";

contract AlgebraHelper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    uint16 internal constant _BASE_FEE = 100;
    int24 internal constant _TICK_SPACING = 60;

    struct Tick {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        int24 index; // tick index
    }

    function getTicks(IAlgebra pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        (,int24 tick,,,,,) = pool.globalState();

        tickRange *= _TICK_SPACING;
        int24 fromTick = tick - tickRange;
        int24 toTick = tick + tickRange;
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / _TICK_SPACING)));

        uint256 counter = 0;
        int16 pos = int16((fromTick / _TICK_SPACING) >> 8);
        int16 endPos = int16((toTick / _TICK_SPACING) >> 8);
        for (; pos <= endPos; pos++) {
            uint256 bm = pool.tickTable(pos);

            while (bm != 0) {
                uint8 bit = _leastSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = ((int24(pos) << 8) | int24(uint24(bit))) * _TICK_SPACING;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityTotal,
                int128 liquidityDelta,
                uint256 outerFeeGrowth0Token,
                uint256 outerFeeGrowth1Token
                , // int56 outerTickCumulative,
                , // uint160 outerSecondsPerLiquidity
                , // uint32 outerSecondsSpent
                , // bool initialized
            ) = pool.ticks(initTicks[i]);

            ticks[i] = abi.encodePacked(
                liquidityTotal,
                liquidityDelta,
                outerFeeGrowth0Token,
                outerFeeGrowth1Token,
                // outerTickCumulative,
                // outerSecondsPerLiquidity,
                // outerSecondsSpent,
                initTicks[i]
            );
        }
    }

    function _leastSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0, "x is 0");
        x = x & (~x + 1);

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
