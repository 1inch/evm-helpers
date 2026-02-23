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
     * @return result  ABI-encoded bytes:
     *   For each call (32 bytes per packed word):
     *     1 bit    - success (0 or 1)
     *     28 bits  - gasUsed
     *     227 bits - selected return word (value)
     */
    function multicallOneTargetPacked() external returns (bytes memory) {
        assembly {
            if lt(calldatasize(), 26) {
                revert(0, 0)
            }

            let numCalls := shr(240, calldataload(4))
            let target := shr(96, calldataload(6))

            if iszero(numCalls) {
                  mstore(0x00, 0x20)
                  mstore(0x20, 0)
                  return(0x00, 0x40)
            }

            let ptr := mload(0x40)
            mstore(ptr, 0x20)
            let totalSize := mul(32, numCalls)
            mstore(add(ptr, 0x20), totalSize)
            let resultsPtr := add(ptr, 0x40)
            let endPtr := add(resultsPtr, totalSize)
            mstore(0x40, endPtr)

            let calldataPtr := 26

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

            return(ptr, add(totalSize, 0x40))
        }
    }

    /**
     * @notice Executes multiple calls in a single transaction with patchable calldata; reads payload from calldata.
     * @dev All calls are made to the same target. Each entry has one base calldata and multiple patch values; for each patch value
     * the base calldata is copied, the value is written at patchOffset, then the call is made. returnWordIndex selects which
     * 32-byte word of returndata to use (0 = first word). numCalls must equal the total number of patch values across all entries.
     *
     * Calldata layout:
     *   4 bytes  - selector (multicallOneTargetPackedPatchable())
     *   2 bytes  - numCalls (total number of calls)
     *   2 bytes  - numCalldatas (number of base calldata entries)
     *   20 bytes - target address
     *   For each calldata entry:
     *     32 bytes - header (1 byte returnWordIndex | 2 bytes numPatches | 2 bytes patchOffset | dataLength in low bits)
     *     N bytes  - base call data (length = dataLength)
     *     numPatches * 32 bytes - patch values (each written at patchOffset in a copy of base data before the call)
     *
     * @return result ABI-encoded bytes:
     *   For each call (32 bytes per packed word):
     *     1 bit    - success (0 or 1)
     *     28 bits  - gasUsed
     *     227 bits - selected return word (value)
     */
    function multicallOneTargetPackedPatchable() external returns (bytes memory) {
        assembly {
            if lt(calldatasize(), 28) {
                revert(0, 0)
            }

            let numCalls := shr(240, calldataload(4))
            let numCalldatas := shr(240, calldataload(6))
            let target := shr(96, calldataload(8))

            if gt(numCalldatas, numCalls) {
                revert(0, 0)
            }

            if iszero(numCalls) {
                mstore(0x00, 0x20)
                mstore(0x20, 0)
                return(0x00, 0x40)
            }

            let ptr := mload(0x40)
            mstore(ptr, 0x20)
            let totalSize := mul(32, numCalls)
            mstore(add(ptr, 0x20), totalSize)
            let resultsPtr := add(ptr, 0x40)
            let endPtr := add(resultsPtr, totalSize)
            mstore(0x40, endPtr)

            let resultIdx := resultsPtr

            let calldataPtr := 28

            for { let cdIdx := numCalldatas } cdIdx { cdIdx := sub(cdIdx, 1) } {
                let header := calldataload(calldataPtr)
                let returnWordIndex := shr(248, header)
                let numPatches := and(shr(232, header), 0xffff)
                let patchOffset := and(shr(216, header), 0xffff)
                let dataLength := and(header, 0x00000000000000ffffffffffffffffffffffffffffffffffffffffffffffffff)
                calldataPtr := add(calldataPtr, 32)

                let patchesSize := mul(numPatches, 32)
                let calldataEnd := add(calldataPtr, dataLength)
                let patchesEnd := add(calldataEnd, patchesSize)
                 if gt(patchesEnd, calldatasize()) {
                    revert(0, 0)
                }

                calldatacopy(endPtr, calldataPtr, dataLength)

                let offset := mul(returnWordIndex, 32)

                let patchOffsetPtr := add(endPtr, patchOffset)
                
                for { let j := calldataEnd } lt(j, patchesEnd) { j := add(j, 0x20) } {
                    mstore(patchOffsetPtr, calldataload(j))

                    let g := gas()
                    let success := call(g, target, 0, endPtr, dataLength, 0, 0)
                    let gasUsedVal := sub(g, gas())

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
                    mstore(resultIdx, packed)
                    resultIdx := add(resultIdx, 32)
                }

                calldataPtr := patchesEnd
            }

            return(ptr, add(totalSize, 0x40))
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
