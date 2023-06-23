// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

    /// @notice Returns the state of the ticks in a range around the current tick.
    /// @param pool The pool from which to fetch tick data.
    /// @param tickRange The range of ticks to fetch. This is multiplied by the tick spacing to determine the range.
    /// @return ticks An array of bytes containing the tick data.
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

        // ... Rest of function ...

    }

    /// @notice Computes the least significant bit of a number.
    /// @dev Throws if the input number is 0.
    /// @param x The number to compute the least significant bit of.
    /// @return r The least significant bit.
    function _leastSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0, "x is 0");
        // ... Rest of function ...

    }
}
