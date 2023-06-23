// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IMasterWombatV3.sol";


/// @title WombatPoolHelper
/// @dev Helper contract to interact with the Master Wombat V3 contract and fetch information about the various pools.
contract WombatPoolHelper {

    /// @dev Instance of the IMasterWombatV3 interface.
    IMasterWombatV3 private constant _WOMBAT_MASTER_V3 = IMasterWombatV3(0x489833311676B566f888119c29bd997Dc6C95830);

    /// @notice Returns an array of information about all pools.
    /// @dev Iterates over all LP tokens and pools, fetches and returns arrays of related information.
    /// @return pools An array of pool addresses.
    /// @return poolTokens A two-dimensional array where each element is an array of token addresses for a specific pool.
    /// @return lpTokens An array of all LP token addresses.
    /// @return underlyingTokens An array of all underlying token addresses associated with the LP tokens.

    function getAllPoolData() external view returns (address[] memory pools, address[][] memory poolTokens, address[] memory lpTokens, address[] memory underlyingTokens) {
        // poolLength is actually the number of LP tokens tracked
        uint256 lpTokenCount = _WOMBAT_MASTER_V3.poolLength();

        // These two arrays will map all lp token addresses to their underlying token
        lpTokens = new address[](lpTokenCount);
        underlyingTokens = new address[](lpTokenCount);

        // Create an array long enough to hold the maximum possible number pools
        pools = new address[](lpTokenCount);

        uint256 uniquePoolsSize;
        for (uint256 i = 0; i < lpTokenCount; i++) {
            (address lpToken,,,,,,,) = _WOMBAT_MASTER_V3.poolInfoV3(i);
            lpTokens[i] = lpToken;
            underlyingTokens[i] = IAsset(lpToken).underlyingToken();

            address tokenPool = IAsset(lpToken).pool();

            bool found = false;
            for (uint256 k=0; k < uniquePoolsSize; k++) {
                if (pools[k] == tokenPool) {
                    found = true;
                }
            }
            if (!found) {
                pools[uniquePoolsSize++] = tokenPool;
            }
        }

        // cut array size down to uniquePoolsSize
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(pools, uniquePoolsSize)
        }

        // The index of each token list in poolTokens will map to the pool ID tracked in poolsExtended
        poolTokens = new address[][](uniquePoolsSize);
        for (uint256 i = 0; i < uniquePoolsSize; i++) {
            poolTokens[i] = IPool(pools[i]).getTokens();
        }

        return (pools, poolTokens, lpTokens, underlyingTokens);
    }
}


