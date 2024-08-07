// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import { RevertReasonForwarder } from "@1inch/solidity-utils/contracts/libraries/RevertReasonForwarder.sol";
import { SafeERC20 } from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import { IBalanceManager } from "./interfaces/IBalanceManager.sol";

/* solhint-disable avoid-low-level-calls */

abstract contract BalanceManager is IERC1271, IBalanceManager {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    IWETH internal immutable _WETH;

    constructor(IWETH weth) {
        _WETH = weth;
    }

    modifier onlyOwner() virtual;

    receive() external payable {} // solhint-disable-line no-empty-blocks;

    /**
     * @notice See {IBalanceManager-arbitraryCalls}.
     */
    function arbitraryCalls(address[] calldata targets, bytes[] calldata arguments) public onlyOwner {
        unchecked {
            uint256 length = targets.length;
            if (length != arguments.length) revert LengthMismatch();
            for (uint256 i = 0; i < length; ++i) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success,) = targets[i].call(arguments[i]);
                if (!success) RevertReasonForwarder.reRevert();
            }
        }
    }

    /**
     * @notice See {IBalanceManager-arbitraryCallsWithEthCheck}.
     */
    function arbitraryCallsWithEthCheck(address[] calldata targets, bytes[] calldata arguments, uint256 minReturn) external {
        uint256 balanceBefore = msg.sender.balance;
        arbitraryCalls(targets, arguments);
        if (msg.sender.balance - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    /**
     * @notice See {IBalanceManager-arbitraryCallsWithTokenCheck}.
     */
    function arbitraryCallsWithTokenCheck(
        address[] calldata targets,
        bytes[] calldata arguments,
        IERC20 token,
        uint256 minReturn
    ) external {
        uint256 balanceBefore = token.balanceOf(msg.sender);
        arbitraryCalls(targets, arguments);
        if (token.balanceOf(msg.sender) - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    /**
     * @notice See {IBalanceManager-estimateArbitraryCalls}.
     */
    function estimateArbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external onlyOwner {
        unchecked {
            uint256 length = targets.length;
            if (length != arguments.length) revert LengthMismatch();
            bool[] memory statuses = new bool[](length);
            bytes[] memory results = new bytes[](length);
            for (uint256 i = 0; i < length; i++) {
                // solhint-disable-next-line avoid-low-level-calls
                (statuses[i], results[i]) = targets[i].call(arguments[i]);
            }
            revert EstimationResults(statuses, results);
        }
    }

    /**
     * @notice See {IBalanceManager-approve}.
     */
    function approve(IERC20 token, address to) external onlyOwner {
        token.forceApprove(to, type(uint256).max);
    }

    /**
     * @notice See {IBalanceManager-transfer}.
     */
    function transfer(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    /**
     * @notice See {IBalanceManager-batchApprove}.
     */
    function batchApprove(bytes calldata data) external onlyOwner {
        unchecked {
            uint256 length = data.length;
            if (length % 40 != 0) revert InvalidLength();
            for (uint256 i = 0; i < length; i += 40) {
                IERC20(address(bytes20(data[i:i+20]))).forceApprove(address(bytes20(data[i+20:i+40])), type(uint256).max);
            }
        }
    }

    /**
     * @notice See {IBalanceManager-batchTransfer}.
     */
    function batchTransfer(bytes calldata data) external onlyOwner {
        unchecked {
            uint256 length = data.length;
            if (length % 72 != 0) revert InvalidLength();
            for (uint256 i = 0; i < length; i += 72) {
                IERC20 token = IERC20(address(bytes20(data[i:i+20])));
                address target = address(bytes20(data[i+20:i+40]));
                uint256 amount = uint256(bytes32(data[i+40:i+72]));
                token.safeTransfer(target, amount);
            }
        }
    }

    /**
     * @notice See {IBalanceManager-unwrapTo}.
     */
    function unwrapTo(address payable receiver, uint256 amount) external onlyOwner {
        _WETH.safeWithdrawTo(amount, receiver);
    }

    /**
     * @notice See {IBalanceManager-rescueEther}.
     */
    function rescueEther() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert ETHTransferFailed();
    }
}

/* solhint-enable avoid-low-level-calls */
