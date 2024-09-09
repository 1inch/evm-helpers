pragma solidity >=0.8.2 <0.9.0;

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
    function abs(int32 x) private pure returns (int32) {
        return x >= 0 ? x : -x;
    }

    struct Tick {
        uint128 reserveA;
        uint128 reserveB;
    }

    function get(Pool pool, int32 xx) public view returns(Pool.State memory state, Tick[] memory reserves) {
        state = pool.getState();
        int32 lower = abs(state.activeTick - xx);
        int32 upper = abs(state.activeTick + xx);
        int32 max = upper > lower ? upper : lower;
        uint32 len = uint32(max*2+1);
        reserves = new Tick[](len);
        for (uint32 i = 0; i < len; i++) {
            Pool.TickState memory tick = pool.getTick(int32(i)-max);
            reserves[i].reserveA = tick.reserveA;
            reserves[i].reserveB = tick.reserveB;
        }
    }
}

