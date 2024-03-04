// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './IFulfillableRegistry.sol';

/**
 * @title FulfillableRegistry
 * @author luisgj
 * @notice This contract is intented to be used as a registry for fulfillable services.
 * It will store the address of the contract that implements the fulfillable service.
 * The address can be retrieved by the serviceId.
 * @dev This contract is upgradeable.
 * @dev This contract is Ownable.
 * @dev This contract uses UUPSUpgradeable.
 * 
 */
contract FulfillableRegistry is IFulfillableRegistry, UUPSUpgradeable, OwnableUpgradeable {

    mapping(uint256 => Service) private _serviceRegistry;

    mapping(address => Service[]) private _fulfillers;

    uint256 _serviceCount;

    event ServiceRemoved(uint256 serviceID);

    function initialize() public virtual initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * addService
     * This method must only be called by the owner.
     * @param serviceId the service identifier
     * @param service the service info object
     */
    function addService(uint256 serviceId, Service memory service) external returns (bool) {
        require(
            _serviceRegistry[serviceId].contractAddress == address(0), 
            'FulfillableRegistry: Service already exists'
        );
        _serviceRegistry[serviceId] = service;
        _fulfillers[service.fulfiller].push(service);
        _serviceCount++;
        return true;
    }

    function addFulfiller(address fulfiller) external onlyOwner {
        _fulfillers[fulfiller].push();
    }

    function getService(uint256 serviceId) external view returns (Service memory) {
        require(
            _serviceRegistry[serviceId].contractAddress != address(0), 
            'FulfillableRegistry: Service does not exist'
        );
        return _serviceRegistry[serviceId];
    }

    function removeServiceAddress(uint256 serviceId) external onlyOwner {
        delete _serviceRegistry[serviceId];
        _serviceCount--;
        emit ServiceRemoved(serviceId);
    }
}
