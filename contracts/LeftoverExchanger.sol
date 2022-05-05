// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

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
            // solhint-disable-next-line avoid-tx-origin
            payable(tx.origin).transfer(gasRefund);
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
