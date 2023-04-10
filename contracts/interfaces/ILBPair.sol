// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILBPair {
	function getNextNonEmptyBin(bool _swapForY, uint24 _id) external view returns (uint24 nextId);
    function getBin(uint24 _id) external view returns (uint128 binReserveX, uint128 binReserveY);
}
