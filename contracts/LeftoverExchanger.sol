// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IWETH } from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import { ECDSA } from "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

import { BalanceManager } from "./BalanceManager.sol";

/* solhint-disable avoid-low-level-calls */

contract LeftoverExchanger is BalanceManager {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    address private immutable _OWNER;

    event CallFailure(uint256 i, bytes result);

    error CallFailed(uint256 i, bytes result);

    constructor(IWETH weth, address owner) BalanceManager(weth) {
        _OWNER = owner;
    }

    modifier onlyOwner() override {
        if(msg.sender != _OWNER) revert OnlyOwner();
        _;
    }

    // TODO: deprecated
    function estimateMakeCalls(Call[] calldata calls) external payable onlyOwner {
        unchecked {
            bool[] memory statuses = new bool[](calls.length);
            bytes[] memory results = new bytes[](calls.length);
            for (uint256 i = 0; i < calls.length; i++) {
                (statuses[i], results[i]) = calls[i].to.call{value : calls[i].value}(calls[i].data);
            }
            revert EstimationResults(statuses, results);
        }
    }

    // TODO: deprecated
    function makeCallsNoThrow(Call[] calldata calls) external payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) emit CallFailure(i, result);
            }
        }
    }

    // TODO: deprecated
    function makeCalls(Call[] calldata calls) public payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) revert CallFailed(i, result);
            }
        }
    }

    // TODO: deprecated
    function makeCallsWithEthCheck(Call[] calldata calls, uint256 minReturn) external payable {
        uint256 balanceBefore = msg.sender.balance;
        makeCalls(calls);
        if (msg.sender.balance - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4 magicValue) {
        if (ECDSA.recover(hash, signature) == _OWNER) magicValue = this.isValidSignature.selector;
    }

    function _targetToCheck() internal view override returns(address) {
        return msg.sender;
    }
}

/* solhint-enable avoid-low-level-calls */
