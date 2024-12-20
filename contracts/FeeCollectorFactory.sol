// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract FeeCollectorFactory is UpgradeableBeacon {
    event FeeCollectorDeployed(address feeCollector, bytes32 salt);

    constructor(address implementation, address initialOwner)
        UpgradeableBeacon(implementation, initialOwner)
    {}

    function deployFeeCollector(bytes32 salt) external returns (address) {
        address feeCollector = Create2.deploy(0, salt, abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(this), "")));
        emit FeeCollectorDeployed(feeCollector, salt);
        return feeCollector;
    }

    function getFeeCollectorAddress(bytes32 salt) external view returns (address) {
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(this), ""))));
    }
}
