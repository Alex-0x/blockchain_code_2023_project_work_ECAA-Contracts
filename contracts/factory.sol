//controllare questa factory

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MultiSigWallet.sol";

contract MultiSigWalletFactory {
    event MultiSigWalletDeployed(
        address indexed wallet,
        address indexed creator
    );

    MultiSigWallet[] public deployedWallets;

    function createMultiSigWallet(
        address[] memory _owners,
        uint _numConfirmationsRequired,
        uint _numTreshold
    ) public returns (MultiSigWallet) {
        MultiSigWallet newWallet = new MultiSigWallet(
            _owners,
            _numConfirmationsRequired,
            _numTreshold
        );
        deployedWallets.push(newWallet);

        emit MultiSigWalletDeployed(address(newWallet), msg.sender);
        return newWallet;
    }

    function getDeployedWalletsCount() public view returns (uint) {
        return deployedWallets.length;
    }
}
