// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "deploy-yul/YulDeployer.sol";

contract MyContractTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    address public erc1155YulContract;

    function setUp() public {
        erc1155YulContract = yulDeployer.deployContract("ERC1155Yul");
    }

    function test_basic() public {
        assertEq(true, true);
    }
}
