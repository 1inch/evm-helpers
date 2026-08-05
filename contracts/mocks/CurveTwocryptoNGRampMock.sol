// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @title CurveTwocryptoNGRampMock
/// @notice Test double that behaves like a real Twocrypto-NG pool which is currently ramping A/gamma.
/// @dev Every call is forwarded to the wrapped pool, except `future_A_gamma_time()` which reports a
/// future timestamp. It lets tests exercise the `newton_D` branch of the helpers on real pool state.
contract CurveTwocryptoNGRampMock {
    bytes4 private constant _FUTURE_A_GAMMA_TIME_SELECTOR = 0xf9ed9597; // future_A_gamma_time()

    address private immutable _POOL;

    constructor(address pool) {
        _POOL = pool;
    }

    // solhint-disable-next-line no-complex-fallback, payable-fallback
    fallback(bytes calldata data) external returns (bytes memory) {
        if (bytes4(data) == _FUTURE_A_GAMMA_TIME_SELECTOR) {
            return abi.encode(block.timestamp + 1000);
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = _POOL.staticcall(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly ("memory-safe") {
                revert(add(result, 0x20), mload(result))
            }
        }
        return result;
    }
}
