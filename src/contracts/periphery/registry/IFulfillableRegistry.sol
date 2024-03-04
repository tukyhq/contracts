/**
 * SPDX-License-Identifier: MIT
 * This file is part of the FulfillableRegistry contract.
 * 
 * The FulfillableRegistry contract is a contract that can store the address of the contract that implements the fulfillable service.
 * The address can be retrieved by the serviceId.
 * 
 * The FulfillableRegistry contract is upgradeable.
 * The FulfillableRegistry contract is Ownable.
 * The FulfillableRegistry contract uses UUPSUpgradeable.
 * 
 */
pragma solidity >=0.8.20 <0.9.0;

/**
 * Service definition
 */
struct Service {
    uint256 serviceId;
    address contractAddress;
    address erc20ContractAddress;
    address fulfiller;
    address validator;
    uint256 feeAmount;
}

/**
 * @dev Interface for FulfillableRegistry
 * This interface is intented to be implemented by any contract that wants to be a fulfillable registry.
 */
interface IFulfillableRegistry {

    function addService(uint256 serviceId, Service memory service) external returns (bool);

    function addFulfiller(address fulfiller) external;

    function getService(uint256 serviceId) external view returns (Service memory);

    function removeServiceAddress(uint256 serviceId) external;

}
