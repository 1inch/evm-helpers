// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IJoePair {
	function findFirstNonEmptyBinId(uint24 _id, bool _swapForY) external view returns (uint24);
    function getBin(uint24 _id) external view returns (uint256 reserveX, uint256 reserveY);
}
