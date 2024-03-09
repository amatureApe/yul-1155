// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "deploy-yul/YulDeployer.sol";

contract MyContractTest is Test {
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

    // This test is broken up into a few different functions to get around Stack Too Deep
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
