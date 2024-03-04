// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./periphery/validators/IIdentifierValidator.sol";
import "./ITukyERC20Fulfillable.sol";
import "./periphery/registry/IFulfillableRegistry.sol";
import "./FulfillmentTypes.sol";


/**
 * ----- TukyERC20RouterV1 -----
 * This Smart Contract is intented to be user-facing.
 * Any valid address can request a fulfillment to a valid fulfillable.
 * 
 * The contract will validate the request and transfer the payment to the fulfillable contract.
 * -----------------------
 */

contract TukyERC20RouterV1 is 
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable {

    using Address for address payable;
    using Math for uint256;

    address private _fulfillableRegistry;
    address private _tokenRegistry;

    event ServiceRequested(uint256 serviceID, ERC20FulFillmentRequest request);
    event RefValidationFailed(uint256 serviceID, string serviceRef);
  
    /**
     * @dev Constructor.
     */
    function initialize(address serviceRegistry, address tokenRegistry) public virtual initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
        _fulfillableRegistry = serviceRegistry;
        _tokenRegistry = tokenRegistry;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev required for UUPS upgrades
     **/
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * requestService
     * @return true if amount was transferred to the escrow.
     * Pre-conditions:
     * 
     * - verified identifier
     * - valid fulfillable id
     * - valid IIdentifierValidator contract
     * - positive amount
     * - positive fiat amount in precision 2
     * - enough balance on the sender account
     * 
     * 
     * Post-conditions:
     * - payment due is transferred to escrow contract until fulfillment
     */
    function requestService(
        uint256 serviceID, ERC20FulFillmentRequest memory request) public payable whenNotPaused returns (bool)
    {
        require(request.tokenAmount > 0, "Amount must be greater than zero");
        require(request.fiatAmount > 0, "Fiat amount is invalid");
        Service memory service = IFulfillableRegistry(_fulfillableRegistry).getService(serviceID);
        require(
            IIdentifierValidator(service.validator).matches(request.serviceRef),
            "The service identifier failed to validate"
        );
        (bool success, uint256 total_amount) = request.tokenAmount.tryAdd(service.feeAmount);
        require(success, "Overflow while adding fee and amount");
        require(msg.value == total_amount, "Transaction total does not match fee + amount.");
        ITukyERC20Fulfillable(service.erc20ContractAddress).depositERC20(request);
        emit ServiceRequested(serviceID, request);
        return true;
    }
    
}
