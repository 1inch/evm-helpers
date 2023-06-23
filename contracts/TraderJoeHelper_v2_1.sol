// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/ILBPair.sol";

/// @title TraderJoeHelper_v2_1
/// @dev Helper contract for interacting with TraderJoe pair contracts.
// solhint-disable-next-line contract-name-camelcase
contract TraderJoeHelper_v2_1 {

    /// @dev Struct to hold data about a liquidity bin.
    struct BinData {
        uint256 id;
        uint256 reserveX;
        uint256 reserveY;
    }

    /// @notice Retrieves information about specific bins in an ILBPair contract.
    /// @dev Iterates over bins of a pair starting from offset to last non-empty bin or until size bins have been collected.
    ///      Then, collects reserves and id of each non-empty bin and stores them in a struct.
    ///      If end of the bins is reached before size bins are collected, the loop wraps around and starts from the first bin.
    /// @param pair The ILBPair contract to retrieve bin data from.
    /// @param offset The bin id to start collecting data from.
    /// @param size The maximum number of bins to collect data from.
    /// @return data An array of BinData structs containing id and reserves for each collected bin.
    /// @return i The bin id where data collection stopped. It is reset to 0 if end of bins was reached before collecting size bins.

    function getBins(ILBPair pair, uint24 offset, uint24 size)
        external
        view
        returns (BinData[] memory data, uint24 i)
    {
        uint256 counter = 0;
        data = new BinData[](size);
        uint24 lastBin = pair.getNextNonEmptyBin(true, type(uint24).max);
        for (
            i = offset;
            i < lastBin && counter < size;
            i = pair.getNextNonEmptyBin(false, i)
        ) {
            (uint256 x, uint256 y) = pair.getBin(i);
            if (x > 0 || y > 0) {
                (data[counter].reserveX, data[counter].reserveY) = (x, y);
                data[counter].id = i;
                unchecked{ ++counter; }
            }
        }
        if (i == lastBin && counter < size) {
            (data[counter].reserveX, data[counter].reserveY) = pair.getBin(i);
            data[counter].id = i;
            unchecked{ ++counter; }
            i = 0;
        }
        // cut array size down
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(data, counter)
        }
    }
}
