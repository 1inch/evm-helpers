// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

/* solhint-disable avoid-low-level-calls */
contract LeftoverExchanger is Ownable, IERC1271 {
    using SafeERC20 for IERC20;

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    event CallFailure(uint256 i, bytes result);

    error OnlyCreator();
    error CallFailed(uint256 i, bytes result);
    error InvalidLength();
    error EstimationResults(bool[] statuses, bytes[] results);
    error NotEnoughProfit();

    address private immutable _creator;

    constructor(address owner_, address creator_) {
        transferOwnership(owner_);
        _creator = creator_;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function estimateMakeCalls(Call[] calldata calls) external payable onlyOwner {
        unchecked {
            bool[] memory statuses = new bool[](calls.length);
            bytes[] memory results = new bytes[](calls.length);
            for (uint256 i = 0; i < calls.length; i++) {
                (statuses[i], results[i]) = calls[i].to.call{value : calls[i].value}(calls[i].data);
            }
            revert EstimationResults(statuses, results);
        }
    }

    function makeCallsNoThrow(Call[] calldata calls) external payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) emit CallFailure(i, result);
            }
        }
    }

    function makeCalls(Call[] calldata calls) public payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) revert CallFailed(i, result);
            }
        }
    }

    function makeCallsWithEthCheck(Call[] calldata calls, uint256 minReturn) external payable {
        uint256 balanceBefore = msg.sender.balance;
        makeCalls(calls);
        if (msg.sender.balance - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    function approve(IERC20 token, address to) external onlyOwner {
        token.forceApprove(to, type(uint256).max);
    }

    function transfer(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function batchApprove(bytes calldata data) external onlyOwner {
        unchecked {
            uint256 length = data.length;
            if (length % 40 != 0) revert InvalidLength();
            for (uint256 i = 0; i < length; i += 40) {
                IERC20(address(bytes20(data[i:i+20]))).forceApprove(address(bytes20(data[i+20:i+40])), type(uint256).max);
            }
        }
    }

    function batchTransfer(bytes calldata data) external onlyOwner {
        unchecked {
            uint256 length = data.length;
            if (length % 72 != 0) revert InvalidLength();
            for (uint256 i = 0; i < length; i += 72) {
                IERC20 token = IERC20(address(bytes20(data[i:i+20])));
                address target = address(bytes20(data[i+20:i+40]));
                uint256 amount = uint256(bytes32(data[i+40:i+72]));
                token.safeTransfer(target, amount);
            }
        }
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (ECDSA.recover(hash, signature) == owner()) magicValue = this.isValidSignature.selector;
    }

    function destroy() external {
        if (msg.sender != _creator) revert OnlyCreator();
        selfdestruct(payable(this));
    }
}

/* solhint-enable avoid-low-level-calls */
