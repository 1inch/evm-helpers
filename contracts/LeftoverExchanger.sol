// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";


contract LeftoverExchanger is Ownable {
    event Action (bool success, address to, bytes result);

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    constructor(address owner_) {
        transferOwnership(owner_);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // payable for paths with 0x
    function makeCallsNoThrow(Call[] calldata calls) external payable onlyOwner {
        uint256 startGas = gasleft();
        for (uint i = 0; i < calls.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
            emit Action(ok, calls[i].to, result);
        }
        uint256 gasRefund = (startGas - gasleft() + 21000 + (msg.data.length * 7) + 2000) * tx.gasprice;
        if (address(this).balance >= gasRefund) {
            (bool ok,) = payable(owner()).call{value: gasRefund}("");
            require(ok, "refund failed");
        }
    }

    // payable for paths with 0x
    function makeCalls(Call[] calldata calls) external payable onlyOwner {
        for (uint i = 0; i < calls.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool ok,) = calls[i].to.call{value : calls[i].value}(calls[i].data);
            require(ok, "swap failed");
        }
    }
}
