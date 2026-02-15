// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface EulerPool {
       struct Params {
       // Entities
       address vault0;
       address vault1;
       address eulerAccount;
       // Curve
       uint112 equilibriumReserve0;
       uint112 equilibriumReserve1;
       uint256 priceX;
       uint256 priceY;
       uint256 concentrationX;
       uint256 concentrationY;
       // Fees
       uint256 fee;
       uint256 protocolFee;
       address protocolFeeRecipient;
   }

    function getParams() external view returns (Params memory);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 status);
}

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
    uint256 private constant _MAX_U112 = type(uint112).max;

    function calcLimits(EulerPool _pool) external view returns (uint256, uint256, uint256, uint256) {
            EulerPool.Params memory params = _pool.getParams();
            (uint112 reserve0, uint112 reserve1,) = _pool.getReserves();

            IEVault vault0 = IEVault(params.vault0);
            IEVault vault1 = IEVault(params.vault1);
            return (_calcInLimit(params.eulerAccount, vault0), _calcInLimit(params.eulerAccount, vault1),
                    _calcOutLimit(params.eulerAccount, vault0, reserve0), _calcOutLimit(params.eulerAccount, vault1, reserve1));
    }

    function _calcInLimit(address eulerAccount, IEVault vault) internal view returns (uint256) {
        uint256 maxDeposit = vault.debtOf(eulerAccount) + vault.maxDeposit(eulerAccount);
        return maxDeposit < _MAX_U112 ? maxDeposit : _MAX_U112;
    }

    function _calcOutLimit(address eulerAccount, IEVault vault, uint112 reserveLimit) internal view returns (uint256) {
        uint256 outLimit = _MAX_U112;

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
            uint256 maxWithdraw = _decodeCap(uint256(borrowCap));
            maxWithdraw = vault.totalBorrows() > maxWithdraw ? 0 : maxWithdraw - vault.totalBorrows();
            if (maxWithdraw < outLimit) {
                maxWithdraw += vault.convertToAssets(vault.balanceOf(eulerAccount));
                if (maxWithdraw < outLimit) outLimit = maxWithdraw;
            }
        }

        return outLimit;
    }

    function _decodeCap(uint256 amountCap) internal pure returns (uint256) {
        if (amountCap == 0) return type(uint256).max;

        unchecked {
            // Cannot overflow because this is less than 2**256:
            //   10**(2**6 - 1) * (2**10 - 1) = 1.023e+66
            return 10 ** (amountCap & 63) * (amountCap >> 6) / 100;
        }
    }
}
