// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract Ether {
    function balanceOf(address wallet) external view returns (uint256) {
        return wallet.balance;
    }
}
