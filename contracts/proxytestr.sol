// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract MultisigWalletFactory  {
   address public implementationContract;

  constructor(address _implementationContract) {
    implementationContract = _implementationContract;
  }
    event ProxyCreated(address proxy);
   
//  function deployMinimal(address _logic, address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) internal returns (address proxy) {
//     // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
//     bytes20 targetBytes = bytes20(_logic);
//     assembly {
//       let clone := mload(0x40)
//       mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
//       mstore(add(clone, 0x14), targetBytes)
//       mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
//       proxy := create(0, clone, 0x37)
//     }
    
//     emit ProxyCreated(address(proxy));
    
   
   
    
//       bytes memory data = abi.encodeWithSignature("initialize(address,uint,uint)", _owners, _numConfirmationsRequired, _numTreshold);
//       (bool success,) = proxy.call(data);
//       require(success);
    
//   }

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
       

       bytes memory data = abi.encodeWithSignature("initialize(address[],uint,uint)", _owners, _numConfirmationsRequired, _numTreshold);
       (bool success,) = instance.call(data);
       require(success, "problema qui");

      return instance;
    
        
    }
    
    
  function createWallet(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) public returns (address){
    // string memory owners = bytes32ToString(abi.encodePacked(_owners));
    // string memory numConfirmationsRequired = Strings.toString(_numConfirmationsRequired);
    // string memory numTreshold = Strings.toString(_numTreshold);
    address proxy = clone(implementationContract, _owners, _numConfirmationsRequired, _numTreshold);
    return proxy;
  }
}

