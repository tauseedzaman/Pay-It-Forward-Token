// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/PIFToken.sol";

contract PIFTokenTest is Test {
    PIFToken pifToken;
    address owner;
    address recipient;
    address liquidityPair;
    address feeAddress;

    function setUp() public {
        pifToken = new PIFToken();
        owner = address(this); // Set test contract as owner
        recipient = address(0x123);
        liquidityPair = address(0x9999);
        feeAddress = address(0xABCD);
    }

    function testInitialSupply() public {
        uint256 initialSupply = pifToken.totalSupply();
        assertEq(
            initialSupply,
            500_000_000 * 10 ** 18,
            "Initial supply should be 500 million"
        );
    }

    function testOwner() public {
        assertEq(
            pifToken.owner(),
            owner,
            "Owner should be the deploying address"
        );
    }

    function testSetFeeAddress() public {
        pifToken.setFeeAddress(feeAddress);
        assertEq(
            pifToken.feeAddress(),
            feeAddress,
            "Fee address should be set correctly"
        );
    }

    function testTransferWithoutFees() public {
        uint256 amountToTransfer = 1000 * 10 ** 18;
        pifToken.transfer(recipient, amountToTransfer);
        uint256 recipientBalance = pifToken.balanceOf(recipient);
        assertEq(
            recipientBalance,
            amountToTransfer,
            "Recipient should receive tokens without fees"
        );
    }

    function testTransferWithFees() public {
        address newLiquidityPair = address(0x99999);
        pifToken.setFeeAddress(feeAddress);
        pifToken.addLiquidityPair(newLiquidityPair);

        uint256 amountToTransfer = 1000 * 10 ** 18;

        // Transfer tokens from owner to liquidity pair (fee should apply)
        pifToken.transfer(newLiquidityPair, amountToTransfer);

        // Calculate expected fee (3% of 1000)
        uint256 expectedFee = (amountToTransfer * 300) / 10000; // 3%
        uint256 expectedAmountAfterFee = amountToTransfer - expectedFee;

        // Assert recipient balance after fee deduction
        uint256 recipientBalance = pifToken.balanceOf(newLiquidityPair);
        assertEq(
            recipientBalance,
            expectedAmountAfterFee,
            "Recipient should receive tokens after fee deduction"
        );
    }

    function testSetBuySellFeePercentage() public {
        uint16 newFeePercentage = 200; // 2%
        pifToken.setBuySellFeePercentage(newFeePercentage);
        assertEq(
            pifToken.buySellFeePercentage(),
            newFeePercentage,
            "Buy/sell fee percentage should be updated"
        );
    }

    function testAddAndRemoveLiquidityPair() public {
        pifToken.addLiquidityPair(liquidityPair);
        assertTrue(
            pifToken.liquidityPairs(liquidityPair),
            "Liquidity pair should be added"
        );

        pifToken.removeLiquidityPair(liquidityPair);
        assertFalse(
            pifToken.liquidityPairs(liquidityPair),
            "Liquidity pair should be removed"
        );
    }

    function testTransferOwnership() public {
        address newOwner = address(0x789);
        pifToken.transferOwnership(newOwner);
        assertEq(
            pifToken.pendingOwner(),
            newOwner,
            "Pending owner should be set"
        );

        vm.prank(newOwner);
        pifToken.confirmOwnershipTransfer();
        assertEq(pifToken.owner(), newOwner, "Ownership should be transferred");
    }

    function testBurnTokens() public {
        uint256 amountToBurn = 1000 * 10 ** 18;
        uint256 initialSupply = pifToken.totalSupply();

        pifToken.burn(amountToBurn);

        uint256 finalSupply = pifToken.totalSupply();
        assertEq(
            finalSupply,
            initialSupply - amountToBurn,
            "Supply should decrease by burned amount"
        );
    }

    function testUpdateBuySellFeePercentageFailsForInvalidValue() public {
        vm.expectRevert("Fee must be between 1 and 300 basis points");
        pifToken.setBuySellFeePercentage(400); // Exceeds max limit
    }
}
