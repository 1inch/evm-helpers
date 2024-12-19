// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IWETH } from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import { ECDSA } from "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

import { BalanceManager } from "./BalanceManager.sol";

contract FeeCollector is BalanceManager {
    address private immutable _OWNER;
    address private immutable _LIMIT_ORDER_PROTOCOL;

    constructor(IWETH weth, address lop, address owner) BalanceManager(weth) {
        _OWNER = owner;
        _LIMIT_ORDER_PROTOCOL = lop;
    }

    modifier onlyOwner() override {
        if(msg.sender != _OWNER) revert OnlyOwner();
        _;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4 magicValue) {
        address signer;
        if (msg.sender == _LIMIT_ORDER_PROTOCOL) {
            signer = ECDSA.recover(hash, signature);
        } else {
            signer = ECDSA.recover(keccak256(abi.encodePacked(hash, address(this))), signature);
        }

        if (signer == _OWNER) magicValue = this.isValidSignature.selector;
    }

    function _targetToCheck() internal view override returns(address) {
        return address(this);
    }
}
