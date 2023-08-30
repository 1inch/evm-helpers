// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IJoePair.sol";

/// @title TraderJoeHelper
/// @notice A helper contract for interacting with Trader Joe's liquidity pool pairs.
contract TraderJoeHelper {

    /// @dev Represents data about a bin in a Trader Joe pair.
    struct BinData {
        uint256 id;
        uint256 reserveX;
        uint256 reserveY;
    }

    /**
     * @notice Fetches data about a range of bins in a given Trader Joe pair.
     * @param pair The Trader Joe pair to fetch bin data from.
     * @param offset The ID of the first bin to fetch data from.
     * @param size The maximum number of bins to fetch data for.
     * @return data An array of BinData structs containing data about each bin.
     * @return i The bin id where data collection stopped. It is reset to 0 if end of bins was reached before collecting size bins.
     */
    function getBins(IJoePair pair, uint24 offset, uint24 size)
        external
        view
        returns (BinData[] memory data, uint24 i)
    {
        uint256 counter = 0;
        data = new BinData[](size);
        uint24 lastBin = pair.findFirstNonEmptyBinId(type(uint24).max, true);
        for (
            i = offset;
            i < lastBin && counter < size;
            i = pair.findFirstNonEmptyBinId(i, false)
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
