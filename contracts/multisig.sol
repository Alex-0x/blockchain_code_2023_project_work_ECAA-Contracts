// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MultiSigWallet is Initializable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    enum ProposalType {
        Transaction,
        NewOwner,
        RemoveOwner,
        ChangeThreshold,
        ChangeOwner,
        TokenTransaction,
        NFTTransaction
    }

    struct Proposal {
        uint index;
        bool executed;
        uint numConfirmations;
        ProposalType proposalType;
        bytes proposalData;
    }

    Proposal[] public  proposals;
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired; // TODO non dobbiamo far modificare anche questo?
    uint public numThreshold;

    /*
     **********
     * EVENTS
     **********
     */

    // GENERIC EVENTS
    event Deposit(address indexed sender, uint amount, uint balance);
    event ConfirmProposal(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    // TRANSACTION EVENTS
    event ProposeTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed to,
        uint value
    );
    event ExecuteTransaction(address indexed owner, uint indexed proposalIndex);

    // NEW OWNER EVENTS
    event ProposeNewOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed newOwner
    );
    event ExecuteNewOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed newOwner
    );

    // REMOVE OWNER EVENTS
    event ProposeRemoveOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed addressToRemove
    );
    event ExecuteRemoveOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed addressToRemove
    );

    // CHANGE Threshold EVENTS
    event ProposeChangeThreshold(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumThreshold
    );
    event ExecuteChangeThreshold(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumThreshold
    );

    // CHANGE OWNER EVENTS
    event ProposeChangeOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address oldOwner,
        address indexed newOwner
    );
    event ImAmHere(address indexed owner, uint indexed proposalIndex);
    event ExecuteChangeOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address oldOwner,
        address indexed newOwner
    );

    // TOKEN TRANSACTION EVENTS
    event ProposeTokenTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address tokenAddress,
        address to,
        uint value
    );
    event ExecuteTokenTransaction(
        address indexed owner,
        uint indexed proposalIndex
    );

    // NFT TRANSACTION EVENTS
    event ProposeNFTTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address NFTAddress,
        address to,
        uint value
    );
    event ExecuteNFTTransaction(
        address indexed owner,
        uint indexed proposalIndex
    );

    /*
     **********
     * MODIFIER
     **********
     */

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Must be an owner");
        _;
    }

    modifier proposalExists(uint _proposalIndex) {
        require(_proposalIndex < proposals.length, "Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint _proposalIndex) {
        require(
            !proposals[_proposalIndex].executed,
            "Proposal already executed"
        );
        _;
    }

    modifier proposalNotConfirmed(uint _proposalIndex) {
        require(
            !isConfirmed[_proposalIndex][msg.sender],
            "Proposal already confirmed by this owner"
        );
        _;
    }

    function initialize(
        address[] memory _owners,
        uint _numConfirmationsRequired,
        uint _numThreshold
    ) external initializer {
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations number"
        );
        require(
            _numThreshold > 0 && _numThreshold < _owners.length,
            "invalid number of required threshold confirmations number"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        numThreshold = _numThreshold;
    }

    /*
     **********
     * GENERIC FUNCTIONS
     **********
     */

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function confirmProposal(
        uint _txIndex
    )
        public
        onlyOwner
        proposalExists(_txIndex)
        proposalNotExecuted(_txIndex)
        proposalNotConfirmed(_txIndex)
    {
        Proposal storage proposal = proposals[_txIndex];
        proposal.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmProposal(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner proposalExists(_txIndex) proposalNotExecuted(_txIndex) {
        Proposal storage proposal = proposals[_txIndex];

        require(
            isConfirmed[_txIndex][msg.sender],
            "Proposal not confirmed by this owner"
        );

        proposal.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function executeProposal(
        uint _txIndex
    ) public onlyOwner proposalExists(_txIndex) proposalNotExecuted(_txIndex) {
        Proposal storage proposal = proposals[_txIndex];

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.Transaction) {
            _executeTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NewOwner) {
            _executeNewOwner(proposal);
        } else if (proposal.proposalType == ProposalType.RemoveOwner) {
            _executeRemoveOwner(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeThreshold) {
            _executeChangeThreshold(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeOwner) {
            _executeChangeOwner(proposal);
        } else if (proposal.proposalType == ProposalType.TokenTransaction) {
            _executeTokenTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NFTTransaction) {
            _executeNFTTransaction(proposal);
        }
    }

    /*
     **********
     * SPECIFIC FUNCTIONS
     **********
     */

    /**
     * Transactions
     */
    function proposeTransaction(
        address _to,
        uint _value
    )
        public
        //data??
        onlyOwner
    {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.Transaction,
                proposalData: abi.encode(_to, _value)
            })
        );

        emit ProposeTransaction(msg.sender, _proposalIndex, _to, _value);
    }

    function _executeTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, uint _value) = abi.decode(
            proposal.proposalData,
            (address, uint)
        );

        (bool success, ) = _to.call{value: _value}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, proposal.index);
    }

    /**
     * Add Owner
     */
    function proposeNewOwner(address _newOwner) public onlyOwner {
        require(!isOwner[_newOwner], "User is already an owner");
        require(_newOwner != address(0), "New owner can't be zero address");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.NewOwner,
                proposalData: abi.encode(_newOwner)
            })
        );

        emit ProposeNewOwner(msg.sender, _proposalIndex, _newOwner);
    }

    function _executeNewOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        address _newOwner = abi.decode(proposal.proposalData, (address));

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit ExecuteNewOwner(msg.sender, proposal.index, _newOwner);
    }

    /**
     * Remove Owner
     */
    function proposeRemoveOwner(address _addressToRemove) public onlyOwner {
        require(isOwner[_addressToRemove], "User is not an owner");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.RemoveOwner,
                proposalData: abi.encode(_addressToRemove)
            })
        );

        emit ProposeRemoveOwner(msg.sender, _proposalIndex, _addressToRemove);
    }

    function _executeRemoveOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );
        require(owners.length > 1, "At least one owner must remain");

        address _addressToRemove = abi.decode(proposal.proposalData, (address));

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _addressToRemove) {
                // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
                for (uint256 j = i; j < owners.length - 1; j++) {
                    owners[j] = owners[j + 1];
                }
                owners.pop();
                break;
            }
        }

        isOwner[_addressToRemove] = false;

        emit ExecuteRemoveOwner(msg.sender, proposal.index, _addressToRemove);
    }

    /**
     * Change Threshold
     */
    function proposeChangeThreshold(uint _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        require(
            _newThreshold < owners.length,
            "Threshold must be lower than number of owners"
        );

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.ChangeThreshold,
                proposalData: abi.encode(_newThreshold)
            })
        );

        emit ProposeChangeThreshold(msg.sender, _proposalIndex, _newThreshold);
    }

    function _executeChangeThreshold(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        uint _newThreshold = abi.decode(proposal.proposalData, (uint));
        numThreshold = _newThreshold;

        emit ExecuteChangeThreshold(msg.sender, proposal.index, _newThreshold);
    }

    /**
     * Token Transaction
     */
    function proposeTokenTransaction(
        address _to,
        address _tokenAddress,
        uint _value
    ) public onlyOwner {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.TokenTransaction,
                proposalData: abi.encode(_to, _tokenAddress, _value)
            })
        );

        emit ProposeTokenTransaction(
            msg.sender,
            _proposalIndex,
            _to,
            _tokenAddress,
            _value
        );
    }

    function _executeTokenTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, address _tokenAddress, uint _value) = abi.decode(
            proposal.proposalData,
            (address, address, uint)
        );

        IERC20(_tokenAddress).transfer(_to, _value);

        emit ExecuteTokenTransaction(msg.sender, proposal.index);
    }

    /**
     * NFT Transfer
     */
    function proposeNFTTransaction(
        address _to,
        address _NFTAddress,
        uint _NFTid
    ) public onlyOwner {
        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.NFTTransaction,
                proposalData: abi.encode(_to, _NFTAddress, _NFTid)
            })
        );

        emit ProposeNFTTransaction(
            msg.sender,
            _proposalIndex,
            _NFTAddress,
            _to,
            _NFTid
        );
    }

    function _executeNFTTransaction(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        (address _to, address _NFTAddress, uint _NFTid) = abi.decode(
            proposal.proposalData,
            (address, address, uint)
        );

        IERC721(_NFTAddress).safeTransferFrom(address(this), _to, _NFTid);

        emit ExecuteNFTTransaction(msg.sender, proposal.index);
    }

    /**
     * Change Owner
     */
    function proposeChangeOwner(
        address _oldOwner,
        address _newOwner
    ) public onlyOwner {
        require(!isOwner[_newOwner], "User is already an owner");
        require(_newOwner != address(0), "New owner can't be zero address");

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.ChangeOwner,
                proposalData: abi.encode(
                    _oldOwner,
                    _newOwner,
                    false,
                    true,
                    block.timestamp + 2 minutes
                )
            })
        );

        emit ProposeChangeOwner(
            msg.sender,
            _proposalIndex,
            _oldOwner,
            _newOwner
        );
    }

    function _executeChangeOwner(Proposal storage proposal) internal {
        require(
            proposal.numConfirmations >= numThreshold,
            "Number of confirmations too low"
        );

        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        require(!_imHere, "called ImHere function");

        if (block.timestamp >= _timeToUnLock && _lock) {
            _lock = false;
        }

        require(_lock == false, "tempo non ancora passato");

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _oldOwner) {
                owners[i] = _newOwner;
                break;
            }
        }

        isOwner[_oldOwner] = false;
        isOwner[_newOwner] = true;

        emit ExecuteChangeOwner(
            msg.sender,
            proposal.index,
            _oldOwner,
            _newOwner
        );
    }

    // TODO verificare
    function imAmHere(
        uint _proposalIndex
    )
        public
        onlyOwner
        proposalExists(_proposalIndex)
        proposalNotExecuted(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        require(
            proposal.proposalType == ProposalType.ChangeOwner,
            "Can't call this function for this proposal"
        );
       

        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        require(!_imHere, "You have already called this function");

        require(_oldOwner == msg.sender, "You are not the old owner"); // Aggiunto, vedere con gli altri
        require(
            _timeToUnLock - block.timestamp > 0,
            "Time to block execution has expired"
        );

        _imHere = true;
        proposal.proposalData = abi.encode(
            _oldOwner,
            _newOwner,
            _imHere,
            _lock,
            _timeToUnLock
        );

        emit ImAmHere(msg.sender, _proposalIndex);
    }

    function getTimeToUnlock(uint _proposalIndex) public view returns (uint) {
        Proposal storage proposal = proposals[_proposalIndex];
        (
            address _oldOwner,
            address _newOwner,
            bool _imHere,
            bool _lock,
            uint _timeToUnLock
        ) = abi.decode(
                proposal.proposalData,
                (address, address, bool, bool, uint)
            );

        uint timeToUnlock = _timeToUnLock - block.timestamp;
        return timeToUnlock > 0 ? timeToUnlock : 0;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }

    // PROPOSALS E' PUBLIC. ALTRIMENTI METTIAMO PRIVATE E FUNZIONE GETPROPOSAL ONLYOWNER

        function decodeProposalData (uint _proposalIndex) public view  {

             Proposal storage proposal = proposals[_proposalIndex];

             if (proposal.proposalType == ProposalType.Transaction){

                _decodetransactionData(proposal.proposalData);
             }
             else if (proposal.proposalType == ProposalType.NewOwner){
                    
                    _decodeNewOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.RemoveOwner){
    
                    _decodeRemoveOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.ChangeThreshold){
    
                    _decodeChangeThresholdData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.ChangeOwner){
    
                    _decodeChangeOwnerData(proposal.proposalData);
                }
                else if (proposal.proposalType == ProposalType.TokenTransaction){
    
                    _decodeTokenTransactionData(proposal.proposalData);
                
             }
             else if (proposal.proposalType == ProposalType.NFTTransaction){
    
                _decodeNFTTransactionData(proposal.proposalData);    }

            
        }

        function _decodetransactionData (bytes memory proposalData) internal pure returns (address to, uint value){
            return abi.decode(proposalData, (address, uint));
        }

        function _decodeNewOwnerData (bytes memory proposalData) internal pure returns (address newOwner){
            return abi.decode(proposalData, (address));
        }
        function _decodeRemoveOwnerData (bytes memory proposalData) internal pure returns (address addressToRemove){
            return abi.decode(proposalData, (address));
        }
        function _decodeChangeThresholdData (bytes memory proposalData) internal pure returns (uint newNumThreshold){
            return abi.decode(proposalData, (uint));
        }
        function _decodeChangeOwnerData (bytes memory proposalData) internal pure returns (address oldOwner, address newOwner, bool imHere, bool lock, uint timeToUnLock){
            return abi.decode(proposalData, (address, address, bool, bool, uint));
        }
        function _decodeTokenTransactionData (bytes memory proposalData) internal pure returns (address tokenAddress, address to, uint value){
            return abi.decode(proposalData, (address, address, uint));
        }
        function _decodeNFTTransactionData (bytes memory proposalData) internal pure returns (address NFTAddress, address to, uint NFTid){
            return abi.decode(proposalData, (address, address, uint));
        }
}