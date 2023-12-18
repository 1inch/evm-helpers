// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IUniswapV3.sol";

contract SolidlyV3Helper {
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

        uint counter = 0; // solhint-disable-line explicit-types
        for (int24 tickNum = (fromTick / tickSpacing * tickSpacing); tickNum <= (toTick / tickSpacing * tickSpacing); tickNum += (256 * tickSpacing)) {
            int16 pos = int16((tickNum / tickSpacing) >> 8);
            uint256 bm = pool.tickBitmap(pos);

            while (bm != 0) {
                uint8 bit = BitMath.mostSignificantBit(bm);
                initTicks[counter] = (int24(pos) * 256 + int24(int256(uint256(bit)))) * tickSpacing;
                counter += 1;
                bm ^= 1 << bit;
            }
        }

        ticks = new bytes[](counter);
        for (uint i = 0; i < counter; i++) { // solhint-disable-line explicit-types
             ticks[i] = abi.encodePacked(initTicks[i]);
        }
    }
}
