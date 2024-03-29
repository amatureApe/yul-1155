// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "deploy-yul/YulDeployer.sol";

contract ERC1155Yul is Test {
    YulDeployer yulDeployer = new YulDeployer();
    address public token;
    address defaultSender = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    address user1 = address(0x1);
    address user2 = address(0x2);
    uint256 tokenId1 = 1;
    uint256 tokenId2 = 2;

    function setUp() public {
        token = yulDeployer.deployContract("ERC1155Yul");
    }

    function test_basic() public {
        assertEq(true, true);
    }

    function test_readOwner() public {
        address addrInSlot0 = address(uint160(uint256(vm.load(address(token), bytes32(uint256(0))))));
        assertEq(addrInSlot0, defaultSender, "Address in slot 0 does not match expected value");
    }

    function test_mint() public {
        uint256 amount = 100;

        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, amount);
        bytes memory balanceOfData = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);

        (bool mint_success, ) = token.call(mintData);
        (, bytes memory balanceOf_returndata) = token.call(balanceOfData);

        assertEq(mint_success, true);
        assertEq(abi.decode(balanceOf_returndata, (uint256)), amount, "Minting failed");
    }

    function test_batchMint() public {
        address[] memory to = new address[](2);
        to[0] = user1;
        to[1] = user2;

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(defaultSender);
        bytes memory batchMintData = abi.encodeWithSelector(0xd81d0a15, user1, ids, amounts);
        (bool batchMint_success, ) = token.call(batchMintData);

        bytes memory balanceOfData1 = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOf_returndata1) = token.call(balanceOfData1);

        bytes memory balanceOfData2 = abi.encodeWithSelector(0x00fdd58e, user1, tokenId2);
        (, bytes memory balanceOf_returndata2) = token.call(balanceOfData2);

        assertEq(batchMint_success, true);
        assertEq(abi.decode(balanceOf_returndata1, (uint256)), amounts[0], "Batch minting failed for user1 token1");
        assertEq(abi.decode(balanceOf_returndata2, (uint256)), amounts[1], "Batch minting failed for user1 token2");
    }

    function test_burn() public {
        uint256 initialAmount = 100;
        uint256 burnAmount = 50;
    
        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, initialAmount);
        token.call(mintData);
    
        vm.prank(defaultSender);
        bytes memory burnData = abi.encodeWithSelector(0xf5298aca, user1, tokenId1, burnAmount);
        (bool burn_success, ) = token.call(burnData);
    
        bytes memory balanceOfData = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOf_returndata) = token.call(balanceOfData);
    
        assertEq(burn_success, true);
        assertEq(abi.decode(balanceOf_returndata, (uint256)), initialAmount - burnAmount, "Burning failed");
    }

    function test_burnBatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;
    
        uint256[] memory initialAmounts = new uint256[](2);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
    
        uint256[] memory burnAmounts = new uint256[](2);
        burnAmounts[0] = 50;
        burnAmounts[1] = 100;
    
        vm.prank(defaultSender);
        bytes memory batchMintData = abi.encodeWithSelector(0xd81d0a15, user1, ids, initialAmounts);
        (bool batchMint_success, ) = token.call(batchMintData);

        assertEq(batchMint_success, true);
    
        vm.prank(defaultSender);
        bytes memory burnBatchData = abi.encodeWithSelector(0x6b20c454, user1, ids, burnAmounts);
        (bool burnBatch_success, ) = token.call(burnBatchData);
    
        bytes memory balanceOfData1 = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOf_returndata1) = token.call(balanceOfData1);
    
        assertEq(burnBatch_success, true);
        assertEq(abi.decode(balanceOf_returndata1, (uint256)), initialAmounts[0] - burnAmounts[0], "Batch burning failed for user1");
    }

    function test_setApprovalForAll() public {
        uint256[] memory initialAmounts = new uint256[](2);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
    
        vm.prank(defaultSender);
        bytes memory batchMintData = abi.encodeWithSelector(0x156e29f6, user1, [tokenId1, tokenId2], initialAmounts);
        token.call(batchMintData);
    
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory setApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, true);
        (bool setApprovalForAll_success, ) = token.call(setApprovalForAllData);
    
        // Check if the approval was set correctly
        bytes memory isApprovedForAllData = abi.encodeWithSelector(0xe985e9c5, user1, user2);
        (, bytes memory isApprovedForAll_returndata) = token.call(isApprovedForAllData);
    
        assertEq(setApprovalForAll_success, true, "Set approval for all failed");
        assertEq(abi.decode(isApprovedForAll_returndata, (bool)), true, "Approval status is incorrect");
    
        // Remove approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory removeApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, false);
        (bool removeApprovalForAll_success, ) = token.call(removeApprovalForAllData);
    
        // Check if the approval was removed correctly
        (, bytes memory isApprovedForAll_returndata2) = token.call(isApprovedForAllData);
    
        assertEq(removeApprovalForAll_success, true, "Remove approval for all failed");
        assertEq(abi.decode(isApprovedForAll_returndata2, (bool)), false, "Approval status is incorrect after removal");
    }

    function test_safeTransferFrom() public {
        uint256 initialAmount = 100;
        uint256 transferAmount = 50;
    
        // Mint tokens to user1
        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, initialAmount);
        token.call(mintData);
    
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory setApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, true);
        token.call(setApprovalForAllData);
    
        // Transfer tokens from user1 to user2 using safeTransferFrom
        vm.prank(user2);
        bytes memory safeTransferFromData = abi.encodeWithSelector(0x0febdd49, user1, user2, tokenId1, transferAmount);
        token.call(safeTransferFromData);
    
        // Check balances after the transfer
        bytes memory balanceOfUser1Data = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOfUser1_returndata) = token.call(balanceOfUser1Data);
        uint256 user1Balance = abi.decode(balanceOfUser1_returndata, (uint256));
    
        bytes memory balanceOfUser2Data = abi.encodeWithSelector(0x00fdd58e, user2, tokenId1);
        (, bytes memory balanceOfUser2_returndata) = token.call(balanceOfUser2Data);
        uint256 user2Balance = abi.decode(balanceOfUser2_returndata, (uint256));
    
        assertEq(user1Balance, initialAmount - transferAmount, "SafeTransferFrom failed for sender");
        assertEq(user2Balance, transferAmount, "SafeTransferFrom failed for receiver");
    }

    function test_safeBatchTransferFrom() public {
        uint256[] memory initialAmounts = new uint256[](2);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
    
        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;
    
        vm.prank(defaultSender);
        bytes memory batchMintData = abi.encodeWithSelector(0xd81d0a15, user1, ids, initialAmounts);
        (bool batchMint_success, ) = token.call(batchMintData);
    
        assertEq(batchMint_success, true);
        assertBatchMintedAmounts(user1, ids, initialAmounts);
    
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory setApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, true);
        (bool setApprovalForAll_success, ) = token.call(setApprovalForAllData);
    
        // Check if the approval was set correctly
        bytes memory isApprovedForAllData = abi.encodeWithSelector(0xe985e9c5, user1, user2);
        (, bytes memory isApprovedForAll_returndata) = token.call(isApprovedForAllData);
    
        assertEq(setApprovalForAll_success, true, "Set approval for all failed");
        assertEq(abi.decode(isApprovedForAll_returndata, (bool)), true, "Approval status is incorrect");
    
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
    
        vm.prank(user2);
        bytes memory safeBatchTransferFromData = abi.encodeWithSelector(0xfba0ee64, user1, user2, ids, transferAmounts);
        (bool safeBatchTransferFrom_success, ) = token.call(safeBatchTransferFromData);
    
        assertEq(safeBatchTransferFrom_success, true);
        assertBatchTransferredAmounts(user1, user2, ids, initialAmounts, transferAmounts);
    }

    function test_safeTransferFrom_invalidInputs() public {
        uint256 initialAmount = 100;
        uint256 transferAmount = 50;
    
        // Mint tokens to user1
        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, initialAmount);
        token.call(mintData);
    
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory setApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, true);
        token.call(setApprovalForAllData);
    
        // Test transferring to zero address
        vm.prank(user2);
        bytes memory transferToZeroAddressData = abi.encodeWithSelector(0x0febdd49, user1, address(0), tokenId1, transferAmount, "");
        vm.expectRevert();
        token.call(transferToZeroAddressData);
    
        // Test transferring zero amount
        vm.prank(user2);
        bytes memory transferZeroAmountData = abi.encodeWithSelector(0x0febdd49, user1, user2, tokenId1, 0, "");
        vm.expectRevert();
        token.call(transferZeroAmountData);
    
        // Test transferring more than the balance
        vm.prank(user2);
        bytes memory transferExceedingBalanceData = abi.encodeWithSelector(0x0febdd49, user1, user2, tokenId1, initialAmount + 1, "");
        vm.expectRevert();
        token.call(transferExceedingBalanceData);
    
        // Test transferring an invalid token ID
        vm.prank(user2);
        bytes memory transferInvalidTokenIdData = abi.encodeWithSelector(0x0febdd49, user1, user2, 0, transferAmount, "");
        vm.expectRevert();
        token.call(transferInvalidTokenIdData);
    }

    function test_safeTransferFrom_edgeCases() public {
        uint256 maxAmount = type(uint256).max;
    
        // Mint the maximum possible amount of tokens to user1
        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, maxAmount);
        token.call(mintData);
    
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        bytes memory setApprovalForAllData = abi.encodeWithSelector(0xa22cb465, user2, true);
        token.call(setApprovalForAllData);
    
        // Test transferring the maximum possible amount
        vm.prank(user2);
        bytes memory transferMaxAmountData = abi.encodeWithSelector(0x0febdd49, user1, user2, tokenId1, maxAmount, "");
        (bool success, ) = token.call(transferMaxAmountData);
        require(success, "SafeTransferFrom failed for max amount");
    
        // Check balances after the transfer
        bytes memory balanceOfUser1Data = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOfUser1_returndata) = token.call(balanceOfUser1Data);
        uint256 user1Balance = abi.decode(balanceOfUser1_returndata, (uint256));
    
        bytes memory balanceOfUser2Data = abi.encodeWithSelector(0x00fdd58e, user2, tokenId1);
        (, bytes memory balanceOfUser2_returndata) = token.call(balanceOfUser2Data);
        uint256 user2Balance = abi.decode(balanceOfUser2_returndata, (uint256));
    
        assertEq(user1Balance, 0, "SafeTransferFrom failed to transfer all tokens from sender");
        assertEq(user2Balance, maxAmount, "SafeTransferFrom failed to transfer all tokens to receiver");
    
        // Test transferring to the same address
        vm.prank(user2);
        bytes memory transferToSelfData = abi.encodeWithSelector(0x0febdd49, user2, user2, tokenId1, maxAmount, "");
        (success, ) = token.call(transferToSelfData);
        require(success, "SafeTransferFrom failed for transfer to self");
    
        // Check balance after the transfer to self
        (, bytes memory balanceOfUser2_returndata2) = token.call(balanceOfUser2Data);
        user2Balance = abi.decode(balanceOfUser2_returndata2, (uint256));
    
        assertEq(user2Balance, maxAmount, "SafeTransferFrom failed for transfer to self");
    }
    
    function test_balanceOf() public {
        uint256[] memory initialAmounts = new uint256[](2);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
    
        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;
    
        vm.prank(defaultSender);
        bytes memory batchMintData = abi.encodeWithSelector(0xd81d0a15, user1, ids, initialAmounts);
        (bool batchMint_success, ) = token.call(batchMintData);
    
        assertEq(batchMint_success, true);
    
        for (uint256 i = 0; i < ids.length; i++) {
            bytes memory balanceOfData = abi.encodeWithSelector(0x00fdd58e, user1, ids[i]);
            (, bytes memory balanceOf_returndata) = token.call(balanceOfData);
            assertEq(abi.decode(balanceOf_returndata, (uint256)), initialAmounts[i], "Balance of user1 for token ID is incorrect");
        }
    }

    function test_balanceOfBatch() public {
        uint256[] memory initialAmounts = new uint256[](2);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
    
        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;
    
        address[] memory accounts = new address[](2);
        accounts[0] = user1;
        accounts[1] = user2;
    
        vm.startPrank(defaultSender);

        bytes memory batchMintData1 = abi.encodeWithSelector(0xd81d0a15, user1, ids, initialAmounts);
        (bool batchMint_success1, ) = token.call(batchMintData1);
        assertEq(batchMint_success1, true, "Batch minting failed for user1");
        assertBatchMintedAmounts(user1, ids, initialAmounts);
    
        bytes memory batchMintData2 = abi.encodeWithSelector(0xd81d0a15, user2, ids, initialAmounts);
        (bool batchMint_success2, ) = token.call(batchMintData2);
        assertEq(batchMint_success2, true, "Batch minting failed for user2");
        assertBatchMintedAmounts(user2, ids, initialAmounts);
    
        bytes memory balanceOfBatchData = abi.encodeWithSelector(0x4e1273f4, accounts, ids);
        (, bytes memory balanceOfBatch_returndata) = token.call(balanceOfBatchData);
    
        uint256[] memory expectedBalances = new uint256[](2);
        expectedBalances[0] = initialAmounts[0];
        expectedBalances[1] = initialAmounts[1];
    
        uint256[] memory returnedBalances = abi.decode(balanceOfBatch_returndata, (uint256[]));
        assertEq(returnedBalances.length, expectedBalances.length, "Returned balances array length mismatch");
    
        for (uint256 i = 0; i < expectedBalances.length; i++) {
            assertEq(returnedBalances[i], expectedBalances[i], "Balance mismatch");
        }
    }

    function test_unauthorizedMinting() public {
        uint256 amount = 100;
    
        vm.prank(user1); // Prank as an unauthorized account
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, amount);
        
        vm.expectRevert(); // Expect the transaction to revert
        token.call(mintData);
    }

    function test_unauthorizedBurning() public {
        uint256 initialAmount = 100;
        uint256 burnAmount = 50;
    
        // Mint tokens to user1
        vm.prank(defaultSender);
        bytes memory mintData = abi.encodeWithSelector(0x156e29f6, user1, tokenId1, initialAmount);
        token.call(mintData);
    
        // Attempt to burn tokens from user2 (unauthorized)
        vm.prank(user2);
        bytes memory burnData = abi.encodeWithSelector(0xf5298aca, user1, tokenId1, burnAmount);
        vm.expectRevert(); // Expect the transaction to revert
        token.call(burnData);
    
        // Check that the balance of user1 remains unchanged
        bytes memory balanceOfData = abi.encodeWithSelector(0x00fdd58e, user1, tokenId1);
        (, bytes memory balanceOf_returndata) = token.call(balanceOfData);
        assertEq(abi.decode(balanceOf_returndata, (uint256)), initialAmount, "Unauthorized burning should not change balance");
    }

    ////////////////////////////////////////////////////////////////
    ////////////////////        HELPERS         ////////////////////
    ////////////////////////////////////////////////////////////////

    function assertBatchMintedAmounts(address account, uint256[] memory ids, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            bytes memory balanceOfData = abi.encodeWithSelector(0x00fdd58e, account, ids[i]);
            (, bytes memory balanceOf_returndata) = token.call(balanceOfData);
            assertEq(abi.decode(balanceOf_returndata, (uint256)), amounts[i], "Batch minting failed");
        }
    }
    
    function assertBatchTransferredAmounts(address from, address to, uint256[] memory ids, uint256[] memory initialAmounts, uint256[] memory transferAmounts) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            bytes memory balanceOfFromData = abi.encodeWithSelector(0x00fdd58e, from, ids[i]);
            (, bytes memory balanceOfFrom_returndata) = token.call(balanceOfFromData);
            assertEq(abi.decode(balanceOfFrom_returndata, (uint256)), initialAmounts[i] - transferAmounts[i], "Safe batch transfer failed for sender");
    
            bytes memory balanceOfToData = abi.encodeWithSelector(0x00fdd58e, to, ids[i]);
            (, bytes memory balanceOfTo_returndata) = token.call(balanceOfToData);
            assertEq(abi.decode(balanceOfTo_returndata, (uint256)), transferAmounts[i], "Safe batch transfer failed for receiver");
        }
    }

}
