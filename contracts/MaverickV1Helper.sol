// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./interfaces/IMaverickV1PoolInspector.sol";

contract MaverickV1Helper {
    struct BinPosition {
        uint128 id;
        uint8 kind;
        int32 lowerTick;
    }

    function getState(IMaverickV1Pool pool, IMaverickV1PoolInspector inspector, uint128 startBin, uint128 endBin)
        external
        view
        returns (int32, uint128, IMaverickV1PoolInspector.BinInfo[] memory, BinPosition[] memory) 
    {
        IMaverickV1Pool.State memory state = pool.getState();
        IMaverickV1PoolInspector.BinInfo[] memory bins = inspector.getActiveBins(pool, startBin, endBin);
        BinPosition[] memory binPositions = new BinPosition[](bins.length);
        for (uint256 i = 0; i < bins.length; ++i) {
            if (bins[i].reserveA == 0 && bins[i].reserveB == 0) {
                continue;
            }   
            if (bins[i].mergeId == 0) {
                binPositions[i] = BinPosition(bins[i].id, bins[i].kind, bins[i].lowerTick); 
            }
        }
        return (
            state.activeTick,
            state.binCounter,
            bins,
            binPositions
        );
    }
}
