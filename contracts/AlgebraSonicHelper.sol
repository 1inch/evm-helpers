// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IAlgebraSonic.sol";

/// @title AlgebraSonicHelper
/// @dev This contract includes helper functions for the Algebra protocol such as Sonic chain version.
contract AlgebraSonicHelper {
    /// @dev Minimum allowed tick value.
    int24 private constant _MIN_TICK = -887272;

    /// @dev Maximum allowed tick value.
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /// @dev Spacing between ticks.
    int24 internal constant _TICK_SPACING = 5;

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
    function getTicks(IAlgebraSonic pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        (,int24 tick) = pool.globalState();

        tickRange *= _TICK_SPACING;
        int24 fromTick = tick - tickRange;
        int24 toTick = tick + tickRange;
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        bytes[] memory rawTicks = new bytes[](uint256(int256((toTick - fromTick + 1) / _TICK_SPACING)));
        uint256 counter = 0;
        int24 closestTick = pool.nextTickGlobal();

        (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            int24 prevTick,
            int24 nextTick,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token
        ) = pool.ticks(closestTick);
        int24 prevClosetTick = prevTick;

        if (liquidityTotal > 0 || liquidityDelta != 0) {
            rawTicks[counter++] = abi.encodePacked(
                liquidityTotal,
                liquidityDelta,
                prevTick,
                nextTick,
                outerFeeGrowth0Token,
                outerFeeGrowth1Token,
                closestTick
            );
        }

        for (int24 currentTick = nextTick; currentTick <= toTick; ) {
            (
                liquidityTotal,
                liquidityDelta,
                prevTick,
                nextTick,
                outerFeeGrowth0Token,
                outerFeeGrowth1Token
            ) = pool.ticks(currentTick);

            if (liquidityTotal > 0 || liquidityDelta != 0) {
                rawTicks[counter++] = abi.encodePacked(
                    liquidityTotal,
                    liquidityDelta,
                    prevTick,
                    nextTick,
                    outerFeeGrowth0Token,
                    outerFeeGrowth1Token,
                    currentTick
                );
            }

            if (nextTick <= currentTick) break;
            currentTick = nextTick;
        }

        for (int24 currentTick = prevClosetTick; currentTick >= fromTick; ) {
            (
                liquidityTotal,
                liquidityDelta,
                prevTick,
                nextTick,
                outerFeeGrowth0Token,
                outerFeeGrowth1Token
            ) = pool.ticks(currentTick);

            if (liquidityTotal > 0 || liquidityDelta != 0) {
                rawTicks[counter++] = abi.encodePacked(
                    liquidityTotal,
                    liquidityDelta,
                    prevTick,
                    nextTick,
                    outerFeeGrowth0Token,
                    outerFeeGrowth1Token,
                    currentTick
                );
            }

            if (prevTick >= currentTick) break;
            currentTick = prevTick;
        }

        // Truncate result with real amount
        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            ticks[i] = rawTicks[i];
        }
    }
}
