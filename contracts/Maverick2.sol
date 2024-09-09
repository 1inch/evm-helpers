// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

interface Pool {
    struct TickState {
        uint128 reserveA;
        uint128 reserveB;
        uint128 totalSupply;
        uint32[4] binIdsByTick;
    }
    struct State {
        uint128 reserveA;
        uint128 reserveB;
        int64 lastTwaD8;
        int64 lastLogPriceD8;
        uint40 lastTimestamp;
        int32 activeTick;
        bool isLocked;
        uint32 binCounter;
        uint8 protocolFeeRatioD3;
    }

    function getTick(int32 tick) external view returns (TickState memory _tick);
    function getState() external view returns (State memory);
}

contract Maverick2TickHelper {
    struct Tick {
        uint128 reserveA;
        uint128 reserveB;
    }

    function get(Pool pool, int32 limit) public view returns(Pool.State memory state, Tick[] memory reserves) {
        state = pool.getState();
        uint32 len = uint32(limit*2+1);
        reserves = new Tick[](len);
        for (uint32 i = 0; i < len; i++) {
            Pool.TickState memory tick = pool.getTick(state.activeTick-limit+int32(i));
            reserves[i].reserveA = tick.reserveA;
            reserves[i].reserveB = tick.reserveB;
        }
    }
}
