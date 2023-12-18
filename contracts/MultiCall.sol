// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @title MultiCall
/// @dev A contract for batching multiple contract function calls into a single transaction.
contract MultiCall {

    /// @dev A struct representing a single call to a contract function.
    struct Call {
        address to; // The address of the contract to call.
        bytes data; // The calldata to send with the call.
    }

    /**
     * @notice Executes multiple calls in a single transaction.
     * @dev The function is not gas-limited and may revert due to out of gas errors.
     * @param calls An array of Call structs, each representing a function call.
     * @return results An array of bytes, each entry being the result of the respective function call.
     */
   function multicall(Call[] memory calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
        }
    }

    /**
     * @notice Executes multiple calls in a single transaction with gas limitations.
     * @dev The function will stop making calls when the remaining gas is less than `gasBuffer`.
     * Passing emtpy calls array (calls.length == 0) will result in having lastSuccessIndex = uint256.max.
     * @param calls An array of Call struct instances representing each call.
     * @param gasBuffer The amount of gas that should remain after the last function call.
     * @return results An array of bytes. Each entry represents the return data of each call.
     * @return lastSuccessIndex The index of the last successful call in the `calls` array.
     */
    function multicallWithGasLimitation(Call[] memory calls, uint256 gasBuffer) public returns (bytes[] memory results, uint256 lastSuccessIndex) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            if (gasleft() < gasBuffer) {
                return (results, i);
            }
        }
        return (results, calls.length - 1);
    }

    /**
     * @notice Executes multiple calls in a single transaction and measures the gas used by each call.
     * @dev This function is not gas-limited and may revert due to out of gas errors.
     * @param calls An array of Call struct instances representing each call.
     * @return results An array of bytes. Each entry represents the return data of each call.
     * @return gasUsed An array of uint256. Each entry represents the amount of gas used by the corresponding call.
     */
   function multicallWithGas(Call[] memory calls) public returns (bytes[] memory results, uint256[] memory gasUsed) {
        results = new bytes[](calls.length);
        gasUsed = new uint256[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            uint256 initialGas = gasleft();
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            gasUsed[i] = initialGas - gasleft();
        }
    }

    /// @notice Fetches the block gas limit.
    /// @return result The block gas limit.
    function gaslimit() external view returns (uint256) {
        return block.gaslimit;
    }

    /// @notice Fetches the remaining gas available for the current transaction.
    /// @return result The remaining gas.
    function gasLeft() external view returns (uint256) {
        return gasleft();
    }

    /// @notice Fetches the block timestamp.
    /// @return result timestamp of the block.
    function getCurrentBlockTimestamp() external view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}
