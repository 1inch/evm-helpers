// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IWETH } from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import { ECDSA } from "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

import { BalanceManager } from "./BalanceManager.sol";

contract FeeCollector is BalanceManager {
    address private immutable _OWNER;

    constructor(IWETH weth, address owner) BalanceManager(weth) {
        _OWNER = owner;
    }

    modifier onlyOwner() override {
        if(msg.sender != _OWNER) revert OnlyOwner();
        _;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4 magicValue) {
        if (ECDSA.recover(hash, signature) == _OWNER) magicValue = this.isValidSignature.selector;
    }

    function _targetToCheck() internal view override returns(address) {
        return address(this);
    }
}
