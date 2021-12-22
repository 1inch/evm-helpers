// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ether.sol";
import "./MultiCall.sol";
import "./UniV3Helper.sol";

//solhint-disable-next-line no-empty-blocks
contract EvmHelpers is Ether, MultiCall, UniV3Helper {}
