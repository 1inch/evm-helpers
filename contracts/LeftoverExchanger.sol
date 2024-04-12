// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

/* solhint-disable avoid-low-level-calls */

contract LeftoverExchanger is IERC1271 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    event CallFailure(uint256 i, bytes result);

    error OnlyOwner(address owner);
    error CallFailed(uint256 i, bytes result);
    error InvalidLength();
    error EstimationResults(bool[] statuses, bytes[] results);
    error NotEnoughProfit();
    error LengthMismatch();

    address private immutable _OWNER;
    IWETH internal immutable _WETH;

    constructor(IWETH weth, address owner) {
        _WETH = weth;
        _OWNER = owner;
    }

    modifier onlyOwner() {
        if(msg.sender != _OWNER) revert OnlyOwner(_OWNER);
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // TODO: deprecated
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

    // TODO: deprecated
    function makeCallsNoThrow(Call[] calldata calls) external payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) emit CallFailure(i, result);
            }
        }
    }

    // TODO: deprecated
    function makeCalls(Call[] calldata calls) public payable onlyOwner {
        unchecked {
            for (uint256 i = 0; i < calls.length; i++) {
                (bool ok, bytes memory result) = calls[i].to.call{value : calls[i].value}(calls[i].data);
                if (!ok) revert CallFailed(i, result);
            }
        }
    }

    // TODO: deprecated
    function makeCallsWithEthCheck(Call[] calldata calls, uint256 minReturn) external payable {
        uint256 balanceBefore = msg.sender.balance;
        makeCalls(calls);
        if (msg.sender.balance - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    function arbitraryCalls(address[] calldata targets, bytes[] calldata arguments) public onlyOwner {
        unchecked {
            uint256 length = targets.length;
            if (targets.length != arguments.length) revert LengthMismatch();
            for (uint256 i = 0; i < length; ++i) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success,) = targets[i].call(arguments[i]);
                if (!success) RevertReasonForwarder.reRevert();
            }
        }
    }

    function arbitraryCallsWithEthCheck(address[] calldata targets, bytes[] calldata arguments, uint256 minReturn) external {
        uint256 balanceBefore = msg.sender.balance;
        arbitraryCalls(targets, arguments);
        if (msg.sender.balance - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    function arbitraryCallsWithTokenCheck(address[] calldata targets, bytes[] calldata arguments, IERC20 token, uint256 minReturn) external {
        uint256 balanceBefore = token.balanceOf(msg.sender);
        arbitraryCalls(targets, arguments);
        if (token.balanceOf(msg.sender) - balanceBefore < minReturn) revert NotEnoughProfit();
    }

    function estimateArbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external onlyOwner {
        unchecked {
            bool[] memory statuses = new bool[](targets.length);
            bytes[] memory results = new bytes[](targets.length);
            for (uint256 i = 0; i < targets.length; i++) {
                // solhint-disable-next-line avoid-low-level-calls
                (statuses[i], results[i]) = targets[i].call(arguments[i]);
            }
            revert EstimationResults(statuses, results);
        }
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

    function unwrapTo(address payable receiver, uint256 amount) external onlyOwner {
        _WETH.safeWithdrawTo(amount, receiver);
    }

    function rescueEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (ECDSA.recover(hash, signature) == _OWNER) magicValue = this.isValidSignature.selector;
    }
}

/* solhint-enable avoid-low-level-calls */
