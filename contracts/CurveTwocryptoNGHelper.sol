// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

interface ICurveTwocryptoNG {
    function MATH() external view returns (address); // solhint-disable-line func-name-mixedcase
    function A() external view returns (uint256); // solhint-disable-line func-name-mixedcase
    function gamma() external view returns (uint256);
    function price_scale() external view returns (uint256); // solhint-disable-line func-name-mixedcase
    function balances(uint256 i) external view returns (uint256);
    function D() external view returns (uint256); // solhint-disable-line func-name-mixedcase
    function future_A_gamma_time() external view returns (uint256); // solhint-disable-line func-name-mixedcase
    function totalSupply() external view returns (uint256);
    function precisions() external view returns (uint256[2] memory);
}

interface ICurveTwocryptoNGMath {
    // solhint-disable-next-line func-name-mixedcase
    function newton_D(uint256 ann, uint256 gamma, uint256[2] memory xUnsorted, uint256 k0Prev) external view returns (uint256);
}

/// @title CurveTwocryptoNGHelper
/// @notice Collects in a single call every value needed to price a Curve Twocrypto-NG pool off-chain.
/// @dev Solidity port of `vyper/2crypto_ng_helper.vy` (Vyper 0.3.10), which is deployed on Arbitrum
/// at 0xa0f3b13fbd36df6dbeb6e4865dfc2ad3a4b5a12d. The port is return-data compatible with the original:
/// the selector stays `prep_calc(address)` = 0x70eeb546 and the response stays 288 bytes laid out as
/// [xp[0], xp[1], D, totalSupply, price_scale, A, gamma, precisions[0], precisions[1]], so existing
/// off-chain consumers keep working unchanged.
contract CurveTwocryptoNGHelper {
    uint256 private constant _N_COINS = 2;
    uint256 private constant _PRECISION = 10 ** 18;

    /**
     * @notice Fetches the pricing state of a Curve Twocrypto-NG pool.
     * @param swap The address of the Twocrypto-NG pool to fetch data from.
     * @return xp Raw pool balances (not scaled by precisions or price scale).
     * @return d Pool invariant; recomputed through the pool's MATH contract while A/gamma are ramping.
     * @return tokenSupply LP token total supply.
     * @return priceScale Pool price scale.
     * @return a Amplification coefficient, as returned by the pool.
     * @return g Gamma; unused by pools running stableswap math, kept for layout compatibility.
     * @return precisions Per-coin precision multipliers.
     */
    // solhint-disable-next-line func-name-mixedcase
    function prep_calc(address swap) external view returns (
        uint256[_N_COINS] memory xp,
        uint256 d,
        uint256 tokenSupply,
        uint256 priceScale,
        uint256 a,
        uint256 g,
        uint256[_N_COINS] memory precisions
    ) {
        ICurveTwocryptoNG pool = ICurveTwocryptoNG(swap);

        precisions = pool.precisions();
        tokenSupply = pool.totalSupply();
        for (uint256 k = 0; k < _N_COINS; k++) {
            xp[k] = pool.balances(k);
        }
        priceScale = pool.price_scale();
        a = pool.A();
        g = pool.gamma();
        d = _calcDRamp(a, g, xp, precisions, priceScale, swap);
    }

    /**
     * @dev Port of `_calc_D_ramp`: the stored invariant is stale while A/gamma are ramping,
     * so it is recomputed by the pool's own MATH contract on scaled balances.
     */
    function _calcDRamp(
        uint256 a,
        uint256 g,
        uint256[_N_COINS] memory xp,
        uint256[_N_COINS] memory precisions,
        uint256 priceScale,
        address swap
    ) private view returns (uint256 d) {
        ICurveTwocryptoNG pool = ICurveTwocryptoNG(swap);
        ICurveTwocryptoNGMath math = ICurveTwocryptoNGMath(pool.MATH());

        d = pool.D();
        if (pool.future_A_gamma_time() > block.timestamp) {
            // NB: in Vyper `_xp = xp` copies the array, in Solidity it would alias the returned
            // `xp`, so the scaled values are written into a fresh array on purpose.
            uint256[_N_COINS] memory scaledXp;
            scaledXp[0] = xp[0] * precisions[0];
            scaledXp[1] = xp[1] * priceScale * precisions[1] / _PRECISION;
            d = math.newton_D(a, g, scaledXp, 0);
        }
    }
}
