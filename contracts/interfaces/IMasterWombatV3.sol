// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAsset {
    function pool() external view returns(address);
    function underlyingToken() external view returns(address);
}

interface IPool {
    function getTokens() external view returns (address[] memory);
}

interface IMasterWombatV3 {
    function poolInfoV3(uint256 i) external view
    returns (
        address lpToken,
        address rewarder,
        uint40 periodFinish,
        uint128 sumOfFactors,
        uint128 rewardRate,
        uint104 accWomPerShare,
        uint104 accWomPerFactorShare,
        uint40 lastRewardTimestamp
    );

    function poolLength() external view returns (uint256);
}
