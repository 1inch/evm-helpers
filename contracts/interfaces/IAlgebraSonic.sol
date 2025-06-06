// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IAlgebraSonic {
    function globalState() external view returns (uint160 price, int24 tick); // returns reduced because forks use different types of returned values that we do not use

    function nextTickGlobal() external view returns (int24);

    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            int24 prevTick,
            int24 nextTick,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token
        );
}
