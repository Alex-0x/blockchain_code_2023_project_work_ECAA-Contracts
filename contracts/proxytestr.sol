// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MultisigWalletFactory  {
   address public implementationContract;

  constructor(address _implementationContract) {
    implementationContract = _implementationContract;
  }
    event ProxyCreated(address proxy);
 function deployMinimal(address _logic, bytes memory _data) public returns (address proxy) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    
    emit ProxyCreated(address(proxy));

    if(_data.length > 0) {
         bytes memory data = abi.encodeWithSignature("initialize(address[] memory,uint,uint)", "");
      (bool success,) = proxy.call(data);
      require(success);
    }    
  }
    
    
  function createWallet(bytes memory _data) public returns (address){
    address proxy = deployMinimal(implementationContract, _data);
    return proxy;
  }
}

