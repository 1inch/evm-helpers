// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMaverickV1Pool.sol";

interface IMaverickV1PoolInspector {
    struct BinInfo {
        uint128 id;
        uint8 kind;
        int32 lowerTick;
        uint128 reserveA;
        uint128 reserveB;
        uint128 mergeId;
    }

    function getActiveBins(
        IMaverickV1Pool pool,
        uint128 startBinIndex,
        uint128 endBinIndex
    ) external view returns (BinInfo[] memory bins);

    function getBinDepth(IMaverickV1Pool pool, uint128 binId) external view returns (uint256 depth);

    function getPrice(IMaverickV1Pool pool)
        external
        view
        returns (
            uint256 sqrtPrice,
            uint256 liquidity,
            uint256 reserveA,
            uint256 reserveB
        );
}
