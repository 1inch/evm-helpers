// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract MultiCallTestTarget {
    error TestRevert();

    function getUint() external pure returns (uint256) {
        return 42;
    }

    function getSeveralWords(uint256 x, uint256 y, uint256 z, uint256 w, uint256 v) external view returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) {
        a = x;
        b = y;
        c = z;
        d = w;
        e = v;
    }

    function doRevert() external view {
        revert TestRevert();
    }
}
