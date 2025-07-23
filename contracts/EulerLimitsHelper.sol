// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IEVault {
    function debtOf(address account) external view returns (uint256);
    function maxDeposit(address account) external view returns (uint256);
    function cash() external view returns (uint256);
    function caps() external view returns (uint256, uint16);
    function totalBorrows() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract EulerLimitsHelper {

    function calcLimits(
        address eulerAccount,
        address _vault0,
        address _vault1,
        uint112 reserve0,
        uint112 reserve1) external view returns (uint256, uint256, uint256, uint256) {
            IEVault vault0 = IEVault(_vault0);
            IEVault vault1 = IEVault(_vault1);
            return (_calcInLimit(eulerAccount, vault0), _calcInLimit(eulerAccount, vault1),
                    _calcOutLimit(eulerAccount, vault0, reserve0), _calcOutLimit(eulerAccount, vault1, reserve1));
    }

    function _calcInLimit(address eulerAccount, IEVault vault) internal view returns (uint256) {
        uint256 maxDeposit = vault.debtOf(eulerAccount) + vault.maxDeposit(eulerAccount);
        return maxDeposit < type(uint112).max ? maxDeposit : type(uint112).max;
    }

    function _calcOutLimit(address eulerAccount, IEVault vault, uint112 reserveLimit) internal view returns (uint256) {
        uint256 outLimit = type(uint112).max;

        // Reserve limit
        if (reserveLimit < outLimit) {
            outLimit = reserveLimit;
        }

        // Cash and borrow cap logic
        {
            uint256 cash = vault.cash();
            if (cash < outLimit) {
                outLimit = cash;
            }

            (, uint16 borrowCap) = vault.caps();
            uint256 maxWithdraw = decodeCap(uint256(borrowCap));
            maxWithdraw = vault.totalBorrows() > maxWithdraw ? 0 : maxWithdraw - vault.totalBorrows();
            if (maxWithdraw < outLimit) {
                maxWithdraw += vault.convertToAssets(vault.balanceOf(eulerAccount));
                if (maxWithdraw < outLimit) outLimit = maxWithdraw;
            }
        }

        return outLimit;
    }

    function decodeCap(uint256 amountCap) internal pure returns (uint256) {
        if (amountCap == 0) return type(uint256).max;

        unchecked {
            // Cannot overflow because this is less than 2**256:
            //   10**(2**6 - 1) * (2**10 - 1) = 1.023e+66
            return 10 ** (amountCap & 63) * (amountCap >> 6) / 100;
        }
    }
}
