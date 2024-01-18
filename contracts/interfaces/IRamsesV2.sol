// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;


interface IRamsesV2 {
    function tickSpacing() external view returns (int24);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick
            // the rest is ignored
        );

    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet
            // the rest is ignored
        );

    function tickBitmap(int16 wordPosition) external view returns (uint256);
}
