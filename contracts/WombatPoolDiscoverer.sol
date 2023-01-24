// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WombatPoolDiscoverer {

    address private constant WOMBAT_MASTER_V3 = 0x489833311676B566f888119c29bd997Dc6C95830;

    function getAllPoolData() external view returns (address[] memory pools, address[][] memory tokens, address[] memory lpTokens, address[] memory underlyingTokens) {
        // poolLength is actually the number of LP tokens tracked
        uint256 lpTokenCount = Wombat(WOMBAT_MASTER_V3).poolLength();

        // These two arrays will map all lp token addresses to their underlying token
        lpTokens = new address[](lpTokenCount);
        underlyingTokens = new address[](lpTokenCount);

        // Create an array long enough to hold the maximum possible number pools
        address[] memory poolsExtended = new address[](lpTokenCount);

        uint uniquePoolsIndex = 0;
        for (uint i=0; i<lpTokenCount; i++) {
            (address lpToken,,,,,,,) = Wombat(WOMBAT_MASTER_V3).poolInfoV3(i);
            lpTokens[i] = lpToken;
            underlyingTokens[i] = WombatPool(lpToken).underlyingToken();

            address tokenPool = WombatPool(lpToken).pool();

            bool found = false;
            for (uint k=0; k<=uniquePoolsIndex; k++){
                if (poolsExtended[k] == tokenPool) {
                    found = true;
                }
            }
            if (!found) {
                poolsExtended[uniquePoolsIndex] = tokenPool;
                uniquePoolsIndex++;
            }
        }

        // A list of all unique pools
        address[] memory uniquePools = new address[](uniquePoolsIndex);
        // The index of each token list in poolTokens will map to the pool ID tracked in uniquePools
        address[][] memory poolTokens = new address[][](uniquePoolsIndex);
        for (uint q=0; q<uniquePoolsIndex; q++) {
            uniquePools[q] = poolsExtended[q];
            address[] memory tokenList = WombatPoolPool(poolsExtended[q]).getTokens();
            poolTokens[q] = tokenList;
        }

        return (uniquePools, poolTokens, lpTokens, underlyingTokens);
    }
} 

contract Wombat {
    PoolInfoV3[] public poolInfoV3;
    uint256 public poolLength;
}

struct PoolInfoV3 {
    address lpToken;
    IMultiRewarder rewarder;
    uint40 periodFinish;
    uint128 sumOfFactors; 
    uint128 rewardRate; 
    uint104 accWomPerShare; 
    uint104 accWomPerFactorShare;
    uint40 lastRewardTimestamp;
}

contract WombatPool {
    address public pool;
    address public underlyingToken;
}

interface WombatPoolPool {
    function getTokens() external view returns (address[] memory);
}

interface IMultiRewarder {
    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}
