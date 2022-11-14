// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IJoePair {
    function getBin(uint24 _id) external view returns (uint256 reserveX, uint256 reserveY);
}
