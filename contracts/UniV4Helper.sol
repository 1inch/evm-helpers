// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";

interface IHooks {}

interface IPosManager {
    type Currency is address;
    struct PoolKey {
        Currency currency0;
        Currency currency1;
        uint24 fee;
        int24 tickSpacing;
        IHooks hooks;
    }
    function poolKeys(bytes25 poolId) external  view returns(PoolKey memory poolKey);
}

interface IStateView {
        type PoolId is bytes32;
        function getSlot0(PoolId poolId) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee);
        function getTickBitmap(PoolId poolId, int16 tick) external view returns (uint256 tickBitmap);
        function getTickInfo(PoolId poolId, int24 tick) external view returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );
}

interface IPoolManager {
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory);
}

contract UniV4Helper {
    uint256 private constant TICKS_OFFSET = 4;
    bytes32 private constant POOLS_SLOT = bytes32(uint256(6));

    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    IPoolManager private immutable poolManager;
    IStateView private immutable stateView;
    IPosManager private immutable posManager;

    constructor(IPoolManager _poolManager, IStateView _stateView, IPosManager _posManager) {
        poolManager = _poolManager;
        stateView = _stateView;
        posManager = _posManager;
    }

    function _getTickInfoSlot(IStateView.PoolId poolId, int24 tick) internal pure returns (bytes32) {
        bytes32 stateSlot = keccak256(abi.encodePacked(IStateView.PoolId.unwrap(poolId), POOLS_SLOT));
        bytes32 ticksMappingSlot = bytes32(uint256(stateSlot) + TICKS_OFFSET);
        return keccak256(abi.encodePacked(int256(tick), ticksMappingSlot));
    }

    function getTicks(IStateView.PoolId poolId, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = posManager.poolKeys(bytes25(IStateView.PoolId.unwrap(poolId))).tickSpacing;
        (,int24 tick,,) = stateView.getSlot0(poolId);

        tickRange *= tickSpacing;
        int24 fromTick = tick - tickRange;
        int24 toTick = tick + tickRange;
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        int16 pos = int16((fromTick / tickSpacing) >> 8);
        int16 endPos = int16((toTick / tickSpacing) >> 8);

        for (; pos <= endPos; pos++) {
            uint256 bm = stateView.getTickBitmap(poolId, pos);

            while (bm != 0) {
                uint8 bit = BitMath.leastSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = ((int24(pos) << 8) | int24(uint24(bit))) * tickSpacing;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            bytes32 slot = _getTickInfoSlot(poolId, initTicks[i]);
            bytes32[] memory data = poolManager.extsload(slot, 3);
            ticks[i] = abi.encodePacked(data[0], data[1], data[2], initTicks[i]);
        }
        return(ticks);
    }
}

