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
        for (uint256 i = 0; i < calls.length; i++) {
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
        for (uint256 i = 0; i < calls.length; i++) {
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
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 initialGas = gasleft();
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            gasUsed[i] = initialGas - gasleft();
        }
    }

    /**
     * @notice Executes multiple calls in a single transaction (Yul implementation); reads payload from calldata.
     * @dev All calls are made to the same target. returnWordIndex per call selects which 32-byte word of returndata to use (0 = first word).
     *
     * Calldata layout:
     *   4 bytes  - selector (multicallOneTargetPacked())
     *   2 bytes  - numCalls
     *   20 bytes - target address
     *   For each call:
     *     32 bytes - header (1 byte returnWordIndex | 31 bytes dataLength)
     *     N bytes  - call data (length = dataLength)
     *
     * @return result ABI-encoded bytes as above.
     *
     *   32 bytes - payload length
     *   For each call (32 bytes per packed word):
     *     1 bit    - success (0 or 1)
     *     28 bits  - gasUsed
     *     227 bits - selected return word (value)
     */
    function multicallOneTargetPacked() external returns (bytes memory result) {
        assembly {
            if lt(calldatasize(), 26) {
                revert(0, 0)
            }

            let numCalls := shr(240, calldataload(4))
            let target := shr(96, calldataload(6))

            let ptr := mload(0x40)
            if iszero(numCalls) {
                mstore(ptr, 0x20)
                mstore(add(ptr, 0x20), 0)
                return(ptr, 0x40)
            }

            let calldataPtr := 26

            let resultsPtr := add(ptr, 0x20)
            let totalSize := mul(32, numCalls)
            mstore(ptr, totalSize)
            mstore(0x40, add(resultsPtr, totalSize))

            let endPtr := add(resultsPtr, totalSize)

            for { let i := resultsPtr } lt(i, endPtr) { i := add(i, 32) } {
                let header := calldataload(calldataPtr)
                let returnWordIndex := shr(248, header)
                let dataLength := and(header, 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                calldataPtr := add(calldataPtr, 32)

                if gt(add(calldataPtr, dataLength), calldatasize()) {
                    revert(0, 0)
                }

                calldatacopy(endPtr, calldataPtr, dataLength)
                let g := gas()
                let success := call(g, target, 0, endPtr, dataLength, 0, 0)
                let gasUsedVal := sub(g, gas())

                let offset := mul(returnWordIndex, 32)

                let returnWord := 0
                if and(success, iszero(lt(returndatasize(), add(offset, 32)))) {
                    returndatacopy(0, offset, 32)
                    returnWord := mload(0)
                }

                let packed := or(
                    or(
                        shl(255, success),
                        shl(227, and(gasUsedVal, 0x0fffffff))
                    ),
                    and(returnWord, 0x0000000000000007ffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                )
                mstore(i, packed)

                calldataPtr := add(calldataPtr, dataLength)
            }

            result := ptr
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
