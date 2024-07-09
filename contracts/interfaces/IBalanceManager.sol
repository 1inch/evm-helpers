// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface to manage contract balance.
 */
interface IBalanceManager{
    error EstimationResults(bool[] statuses, bytes[] results);
    error ETHTransferFailed();
    error InvalidLength();
    error LengthMismatch();
    error NotEnoughProfit();
    error OnlyOwner(address owner);

    /**
     * @notice Execute arbitrary calls.
     * @param targets Addresses of the contracts to call.
     * @param arguments Data to send to each contract.
     */
    function arbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external;

    /**
     * @notice Execute arbitrary calls and check the ETH balance after.
     * @param targets Addresses of the contracts to call.
     * @param arguments Data to send to each contract.
     * @param minReturn Minimum amount of ETH balance after all calls.
     */
    function arbitraryCallsWithEthCheck(address[] calldata targets, bytes[] calldata arguments, uint256 minReturn) external;

    /**
     * @notice Execute arbitrary calls and check the token balance after.
     * @param targets Addresses of the contracts to call.
     * @param arguments Data to send to each contract.
     * @param token Token to check the balance of.
     * @param minReturn Minimum amount of token balance after all calls.
     */
    function arbitraryCallsWithTokenCheck(
        address[] calldata targets,
        bytes[] calldata arguments,
        IERC20 token,
        uint256 minReturn
    ) external;

    /**
     * @notice Estimate the results of arbitrary calls.
     * @param targets Addresses of the contracts to call.
     * @param arguments Data to send to each contract.
     * @dev This function reverts results with `EstimationResults` error.
     */
    function estimateArbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external;

    /**
     * @notice Approves a spender to spend an infinite amount of tokens.
     * @param token The IERC20 token contract on which the call will be made.
     * @param to The address which will spend the funds.
     */
    function approve(IERC20 token, address to) external;

    /**
     * @notice Transfers a certain amount of tokens to a recipient.
     * @param token The IERC20 token contract on which the call will be made.
     * @param to The address which will receive the funds.
     * @param amount The amount of tokens to transfer.
     */
    function transfer(IERC20 token, address to, uint256 amount) external;

    /**
     * @notice Batch approves a spender to spend an infinite amount of multiple tokens.
     * @param data The data containing the token addresses and the respective spender addresses.
     */
    function batchApprove(bytes calldata data) external;

    /**
     * @notice Batch transfers multiple tokens to the respective recipients.
     * @param data The data containing the token addresses, recipients and amounts.
     */
    function batchTransfer(bytes calldata data) external;

    /**
     * @notice Unwrap the contract's WETH balance to a recipient.
     * @param receiver The address which will receive ETH.
     * @param amount The amount of tokens to unwrap.
     */
    function unwrapTo(address payable receiver, uint256 amount) external;

    /**
     * @notice Rescue all ETH from the contract.
     */
    function rescueEther() external;
}

/* solhint-enable avoid-low-level-calls */
