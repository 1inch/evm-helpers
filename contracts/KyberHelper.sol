// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IKyber.sol";

/// @title KyberHelper
/// @dev A contract that includes helper functions for the Kyber protocol.
contract KyberHelper {

    /**
     * @notice Fetches initialized ticks from a given Kyber pool.
     * @dev The function gets the current state of the pool and fetches the ticks by moving in both directions
     * (previous and next) from the current tick. The number of fetched ticks is limited by `maxTickNum`.
     * @param pool The address of the Kyber pool to fetch the ticks from.
     * @param maxTickNum The maximum number of ticks to fetch.
     * @return ticks The bytes array containing the fetched ticks data.
     */
   function getTicks(IKyber pool, uint256 maxTickNum) external view returns (bytes[] memory ticks) {
        (,,int24 tick,) = pool.getPoolState();

        int24[] memory initTicks = new int24[](maxTickNum);

        uint256 counter = 1;
        initTicks[0] = tick;

        (int24 previous, int24 next) = pool.initializedTicks(tick);
        if (previous != tick && previous != 0) {
            initTicks[counter] = previous;
            counter++;
        }
        if (next != tick && next != 0) {
            initTicks[counter] = next;
            counter++;
        }

        while ((next != 0 || previous != 0)) {
            if (previous != 0) {
                (int24 p, ) = pool.initializedTicks(previous);
                if (previous != p && p != 0) {
                    initTicks[counter] = p;
                    previous = p;
                    counter++;
                } else {
                    previous = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }

            if (next != 0) {
                (, int24 n) = pool.initializedTicks(next);
                if (next != n && n != 0) {
                    initTicks[counter] = n;
                    next = n;
                    counter++;
                } else {
                    next = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                ,
            ) = pool.ticks(initTicks[i]);

             ticks[i] = abi.encodePacked(
                 liquidityGross,
                 liquidityNet,
                 initTicks[i]
             );
        }
    }
}
