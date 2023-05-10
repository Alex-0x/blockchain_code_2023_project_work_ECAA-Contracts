// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/MultiSigWallet.sol";

interface IMultiSig{

 function initialize(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) external;

}

contract MultiSigWalletFactory  {
   address public implementationContract;

  constructor(address _implementationContract) {
    implementationContract = _implementationContract;
  }
    event ProxyCreated(address proxy);
   


function clone(address implementation, address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
       
       IMultiSig(instance).initialize(_owners, _numConfirmationsRequired, _numTreshold);
       
       emit ProxyCreated(address(instance));
       return instance;
            
    }
    
    function createWallet(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) public returns (address){
    address proxy = clone(implementationContract, _owners, _numConfirmationsRequired, _numTreshold);
    return proxy;
  }
}

