// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IUniswapV3.sol";

/// @title UniV3Helper
/// @dev Helper contract to interact with Uniswap V3 pool contracts.
contract UniV3Helper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /**
     * @notice Fetches tick data for a specified range from a Uniswap V3 pool.
     * @dev The function returns an array of bytes each containing packed data about each tick in the specified range.
     * The returned tick data includes the total liquidity, liquidity delta, outer fee growth for the two tokens, and
     * the tick value itself. The tick range is centered around the current tick of the pool and spans tickRange*2.
     * The tick range is constrained by the global min and max tick values.
     * If there are no initialized ticks in the range, the function returns an empty array.
     * @param pool The Uniswap V3 pool from which to fetch tick data.
     * @param tickRange The range (either side of the current tick) within which to fetch tick data.
     * @return ticks An array of bytes each containing packed data about each tick in the specified range.
     */
    function getTicks(IUniswapV3 pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        (,int24 tick) = pool.slot0();

        tickRange *= tickSpacing;
        int24 fromTick = tick - tickRange;
        int24 toTick = tick + tickRange;
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        int16 pos = int16((fromTick / tickSpacing) >> 8);
        int16 endPos = int16((toTick / tickSpacing) >> 8);
        for (; pos <= endPos; pos++) {
            uint256 bm = pool.tickBitmap(pos);

            while (bm != 0) {
                uint8 bit = _leastSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = ((int24(pos) << 8) | int24(uint24(bit))) * tickSpacing;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                uint256 feeGrowthOutside0X128,
                uint256 feeGrowthOutside1X128
                , // int56 tickCumulativeOutside,
                , // secondsPerLiquidityOutsideX128
                , // uint32 secondsOutside
                , // init
            ) = pool.ticks(initTicks[i]);

            ticks[i] = abi.encodePacked(
                liquidityGross,
                liquidityNet,
                feeGrowthOutside0X128,
                feeGrowthOutside1X128,
                // tickCumulativeOutside,
                // secondsPerLiquidityOutsideX128,
                // secondsOutside,
                initTicks[i]
            );
        }
    }

    /**
     * @notice Determines the position of the least significant bit in the given number.
     * @dev The function works by repeatedly halving the number and keeping track of the number of operations
     * performed until the number is less than 2.
     * @param x The input number for which the least significant bit position is to be found.
     * @return r The position of the least significant bit in the given number.
     */
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
