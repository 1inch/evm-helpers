// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title MultiCall
/// @dev A contract for batching multiple contract function calls into a single transaction.
contract MultiCall {

    /// @notice A struct representing a call to a contract function.
    struct Call {
        address to;
        bytes data;
    }

    /// @notice Calls multiple contract functions in a single transaction.
    /// @dev This function is not gas-limited and may revert due to out of gas errors.
    /// @param calls An array of Call structs, each representing a function call.
    /// @return results An array of raw bytes, each entry being the result of the respective function call.

   function multicall(Call[] memory calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
        }
    }


    /// @notice Calls multiple contract functions in a single transaction, with gas limitation.
    /// @dev This function will stop making calls when the remaining gas is less than `gasBuffer`.
    /// @dev Be careful with calls.length == 0
    /// @param calls An array of Call structs, each representing a function call.
    /// @param gasBuffer The amount of gas that should remain after the last function call.
    /// @return results An array of raw bytes, each entry being the result of the respective function call.
    /// @return lastSuccessIndex The index of the last successfully executed function call.
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


    /// @notice Calls multiple contract functions in a single transaction and returns the gas used by each call.
    /// @dev This function is not gas-limited and may revert due to out of gas errors.
    /// @param calls An array of Call structs, each representing a function call.
    /// @return results An array of raw bytes, each entry being the result of the respective function call.
    /// @return gasUsed An array of gas amounts used by each function call.

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
    /// @return The block gas limit.
    function gaslimit() external view returns (uint256) {
        return block.gaslimit;
    }

    /// @notice Fetches the remaining gas available for the current transaction.
    /// @return The remaining gas.
    function gasLeft() external view returns (uint256) {
        return gasleft();
    }
}
