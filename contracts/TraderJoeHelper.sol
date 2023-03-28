// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IJoePair.sol";

contract TraderJoeHelper {
    struct BinData {
        uint256 id;
        uint256 reserveX;
        uint256 reserveY;
    }

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
