// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;


interface IAlgebra {
    /**
    * @notice The globalState structure in the pool stores many values but requires only one slot
    * and is exposed as a single method to save gas when accessed externally.
    * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
    * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
    * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
    * boundary;
    * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
    * Returns timepointIndex The index of the last written timepoint;
    * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
    * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
    * Returns unlocked Whether the pool is currently locked to reentrancy;
    */
    function globalState() external view returns (uint160 price, int24 tick); // returns reduced because forks use different types of returned values that we do not use

    /**
    * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    * @dev This value can overflow the uint256
    */
    function totalFeeGrowth0Token() external view returns (uint256);

    /**
    * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    * @dev This value can overflow the uint256
    */
    function totalFeeGrowth1Token() external view returns (uint256);

    /**
    * @notice The currently in range liquidity available to the pool
    * @dev This value has no relationship to the total liquidity across all ticks.
    * Returned value cannot exceed type(uint128).max
    */
    function liquidity() external view returns (uint128);

    /**
    * @notice Look up information about a specific tick in the pool
    * @dev This is a public structure, so the `return` natspec tags are omitted.
    * @param tick The tick to look up
    * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
    * tick upper
    * @return liquidityDelta how much liquidity changes when the pool price crosses the tick;
    * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
    * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
    * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
    * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
    * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
    * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
    * otherwise equal to false. Outside values can only be used if the tick is initialized.
    * In addition, these values are only relative and must be used only in comparison to previous snapshots for
    * a specific position.
    */
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
    function tickTable(int16 wordPosition) external view returns (uint256);

    /**
    * @notice Returns the information about a position by the position's key
    * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
    * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
    * @return liquidityAmount The amount of liquidity in the position;
    * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
    * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
    * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
    * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
    * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
    */
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidityAmount,
            uint32 lastLiquidityAddTimestamp,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );
}
