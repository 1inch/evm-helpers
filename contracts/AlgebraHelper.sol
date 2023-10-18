// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IAlgebra.sol";

/// @title AlgebraHelper
/// @dev This contract includes helper functions for the Algebra protocol.
contract AlgebraHelper {
    /// @dev Minimum allowed tick value.
    int24 private constant _MIN_TICK = -887272;

    /// @dev Maximum allowed tick value.
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /// @dev Base fee for transactions.
    uint16 internal constant _BASE_FEE = 100;

    /// @dev Spacing between ticks.
    int24 internal constant _TICK_SPACING = 60;

    /// @dev The Tick struct represents the state of a tick.
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

    /**
     * @notice Fetches tick data for a specified range from an Algebra pool.
     * @dev The function returns an array of bytes each containing packed data about each tick in the specified range.
     * The returned tick data includes the total liquidity, liquidity delta, outer fee growth for the two tokens, and
     * the tick value itself. The tick range is centered around the current tick of the pool and spans tickRange*2.
     * The tick range is constrained by the global min and max tick values.
     * If there are no initialized ticks in the range, the function returns an empty array.
     * @param pool The Algebra pool from which to fetch tick data.
     * @param tickRange The range (either side of the current tick) within which to fetch tick data.
     * @return ticks An array of bytes each containing packed data about each tick in the specified range.
     */
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
                uint8 bit = BitMath.leastSignificantBit(bm);
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
}
