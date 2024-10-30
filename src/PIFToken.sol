//! SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Pay It Forward (PIF) Token Contract for thebenefactor.net
 * @dev ERC20 token with buy/sell transaction fees. This contract includes mechanisms for redistributing
 * accumulated fees daily based on defined allocations for Platform Rewards and Platform Operating Expenses.
 * Utilizes OpenZeppelin libraries for ERC20 functionality and pausability.
 */

contract PIFToken is ERC20, Pausable {
    address public owner;
    address public feeAddress; // Address to collect buy/sell fees

    /// @notice Track liquidity pairs to identify fee-applicable transactions
    mapping(address => bool) public liquidityPairs;

    /// @notice Two-step ownership transfer process field
    address public pendingOwner;

    /// @notice The current buy/sell fee percentage, initially 3%
    uint16 public buySellFeePercentage = 300; // Basis points (1 bp = 0.01%)

    /// Events for tracking state changes and actions within the contract
    event BuySellFeePercentageUpdated(uint16 buySellFeePercentage); // Emitted when fee is updated
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    ); // Emitted when ownership is transferred
    event FeeCollected(
        address indexed sender,
        address indexed recipient,
        uint256 feeAmount
    ); // Emitted when a fee is added
    event LiquidityPairAdded(address indexed liquidityPair); // Emitted when a new liquidity pair is added
    event LiquidityPairRemoved(address indexed liquidityPair); // Emitted when a liquidity pair is removed
    event FeeAddressUpdated(address indexed newFeeAddress); // Emitted when fee address is updated

    constructor() ERC20("Pay It Forward", "PIF") {
        _mint(msg.sender, 500_000_000 * 10 ** 18); // 500 million tokens
        owner = msg.sender;
    }

    /// Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Invalid amount");
        _;
    }

    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }

    /**
     * @notice Sets the address to receive accumulated fees.
     * @param _feeAddress The new fee address.
     */
    function setFeeAddress(
        address _feeAddress
    ) external onlyOwner validAddress(_feeAddress) {
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(feeAddress);
    }

    /**
     * @notice Updates the buy/sell transaction fee percentage.
     * @param _feePercentage New fee percentage (basis points, max 300 or 3% ).
     */
    function setBuySellFeePercentage(
        uint16 _feePercentage
    ) external onlyOwner validAmount(_feePercentage) {
        require(
            _feePercentage > 0 && _feePercentage <= 300,
            "Fee must be between 1 and 300 basis points"
        );
        buySellFeePercentage = _feePercentage;
        emit BuySellFeePercentageUpdated(buySellFeePercentage);
    }

    /**
     * @notice Initiates a two-step ownership transfer process to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(
        address newOwner
    ) external virtual onlyOwner validAddress(newOwner) {
        pendingOwner = newOwner;
    }

    /**
     * @notice Completes the ownership transfer if initiated.
     * Can only be called by the pending owner.
     */
    function confirmOwnershipTransfer() external validAddress(msg.sender) {
        require(
            msg.sender == pendingOwner,
            "Only the pending owner can confirm the transfer"
        );

        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * @notice Pauses the contract, disabling all transfers.
     * Callable only by the owner.
     */
    function pause() public onlyOwner {
        super._pause();
    }

    /**
     * @notice Unpauses the contract, re-enabling all transfers.
     * Callable only by the owner.
     */
    function unpause() public onlyOwner {
        super._unpause();
    }

    /**
     * @notice Adds a new liquidity pair address to enable buy/sell fee on transfers.
     * @param liquidityPairAddress The new liquidity pair address.
     */
    function addLiquidityPair(
        address liquidityPairAddress
    ) external onlyOwner validAddress(liquidityPairAddress) {
        liquidityPairs[liquidityPairAddress] = true;
        emit LiquidityPairAdded(liquidityPairAddress);
    }

    /**
     * @notice Removes a liquidity pair address, disabling fee on transfers with that address.
     * @param liquidityPairAddress The liquidity pair address to remove.
     */
    function removeLiquidityPair(
        address liquidityPairAddress
    ) external onlyOwner validAddress(liquidityPairAddress) {
        liquidityPairs[liquidityPairAddress] = false;
        emit LiquidityPairRemoved(liquidityPairAddress);
    }

    /**
     * @notice Applies buy/sell fees to transactions involving liquidity pairs.
     * Transfers the calculated fee to the fee address.
     * @param sender The address sending the tokens.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to transfer.
     * @return The amount after fee deduction.
     */
    function applyBuySellFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        // Only apply fees if transaction involves liquidity pairs
        if (!liquidityPairs[sender] && !liquidityPairs[recipient]) {
            return amount;
        }

        // Calculate fee amount if transaction involves liquidity pairs
        uint256 feeAmount = (amount * buySellFeePercentage) / 10 ** 4;
        super._transfer(sender, feeAddress, feeAmount); // tranfer fees to feeAddress. this is distrubted on the platform
        emit FeeCollected(sender, recipient, feeAmount);
        return amount - feeAmount;
    }

    /**
     * @notice Overrides transfer function to apply fees and pausability.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        validAmount(amount)
        validAddress(recipient)
        returns (bool)
    {
        uint256 transferAmount = applyBuySellFees(
            msg.sender,
            recipient,
            amount
        );
        return super.transfer(recipient, transferAmount);
    }

    /**
     * @notice Overrides transferFrom function to apply fees and pausability.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        validAmount(amount)
        validAddress(sender)
        validAddress(recipient)
        returns (bool)
    {
        uint256 transferAmount = applyBuySellFees(sender, recipient, amount);
        return super.transferFrom(sender, recipient, transferAmount);
    }

    /**
     * @notice Allows the owner to burn a specified amount of tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        uint256 amount
    ) external onlyOwner validAmount(amount) whenNotPaused {
        _burn(msg.sender, amount);
    }
}
