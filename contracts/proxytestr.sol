// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// contract MultiSigWalletFactory is Initializable {
//     address[] public owners;
//     uint256 public numConfirmationsRequired;
//     uint256 public walletId;

//     function initialize(address[] memory _owners, uint256 _numConfirmationsRequired, uint256 _walletId) public initializer {
//         require(_owners.length > 0, "MultisigWallet: Owners array should not be empty");
//         require(_numConfirmationsRequired > 0, "MultisigWallet: Minimum confirmations required should be greater than 0");
//         require(_numConfirmationsRequired <= _owners.length, "MultisigWallet: Required confirmations should not exceed number of owners");

//         for (uint256 i = 0; i < _owners.length; i++) {
//             require(_owners[i] != address(0), "MultisigWallet: Owner address should not be 0");
//             for (uint256 j = i + 1; j < _owners.length; j++) {
//                 require(_owners[i] != _owners[j], "MultisigWallet: Owner addresses should be unique");
//             }
//         }

//         owners = _owners;
//         numConfirmationsRequired = _numConfirmationsRequired;
//         walletId = _walletId;
//     }
// }

