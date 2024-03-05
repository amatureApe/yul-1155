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
}
