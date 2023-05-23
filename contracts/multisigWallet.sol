// License-Identifier: UNLICENSED
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
        ChangeNumConfirmations,
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

    Proposal[] public proposals;
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    uint public numThreshold;

    /*
     **********
     * EVENTS
     **********
     */

    // GENERIC EVENTS
    event Deposit(address indexed sender, uint amount, uint balance);
    event ConfirmProposal(address indexed owner, uint indexed proposalIndex);
    event RevokeConfirmation(address indexed owner, uint indexed proposalIndex);
    event ExecuteProposal(address indexed owner, uint indexed proposalIndex);

    // SPECIFIC EVENTS
    event ProposeTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed to,
        uint value
    );
    event ProposeNewOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed newOwner
    );
    event ProposeRemoveOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address indexed addressToRemove
    );
    event ProposeChangeThreshold(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumThreshold
    );
    event ProposeChangeNumConfirmations(
        address indexed owner,
        uint indexed proposalIndex,
        uint newNumConfirmations
    );
    event ProposeChangeOwner(
        address indexed owner,
        uint indexed proposalIndex,
        address oldOwner,
        address indexed newOwner
    );
    event ImAmHere(address indexed owner, uint indexed proposalIndex);
    event ProposeTokenTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address tokenAddress,
        address to,
        uint value
    );
    event ProposeNFTTransaction(
        address indexed owner,
        uint indexed proposalIndex,
        address NFTAddress,
        address to,
        uint value
    );

    

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
        uint _proposalIndex
    )
        public
        onlyOwner
        proposalExists(_proposalIndex)
        proposalNotExecuted(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.Transaction) {
            _executeTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NewOwner) {
            _executeNewOwner(proposal);
        } else if (proposal.proposalType == ProposalType.RemoveOwner) {
            _executeRemoveOwner(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeThreshold) {
            _executeChangeThreshold(proposal);
        } else if (
            proposal.proposalType == ProposalType.ChangeNumConfirmations
        ) {
            _executeChangeNumConfirmations(proposal);
        } else if (proposal.proposalType == ProposalType.ChangeOwner) {
            _executeChangeOwner(proposal);
        } else if (proposal.proposalType == ProposalType.TokenTransaction) {
            _executeTokenTransaction(proposal);
        } else if (proposal.proposalType == ProposalType.NFTTransaction) {
            _executeNFTTransaction(proposal);
        }

        emit ExecuteProposal(msg.sender, proposal.index);
    }

    /*
     **********
     * SPECIFIC FUNCTIONS
     **********
     */

    /**
     * Transactions
     */
    function proposeTransaction(address _to, uint _value) public onlyOwner {
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
    }

    /**
     * Change Number of Confirmations Required
     */
    function proposeChangeNumConfirmations(
        uint _newNumConfirmations
    ) public onlyOwner {
        require(
            _newNumConfirmations > 0,
            "Number of confirmations must be greater than 0"
        );
        require(
            _newNumConfirmations <= owners.length,
            "Number of confirmations must be lower than number of owners"
        );

        uint _proposalIndex = proposals.length;
        proposals.push(
            Proposal({
                index: _proposalIndex,
                executed: false,
                numConfirmations: 0,
                proposalType: ProposalType.ChangeNumConfirmations,
                proposalData: abi.encode(_newNumConfirmations)
            })
        );

        emit ProposeChangeNumConfirmations(
            msg.sender,
            _proposalIndex,
            _newNumConfirmations
        );
    }

    function _executeChangeNumConfirmations(
        Proposal storage proposal
    ) internal {
        require(
            proposal.numConfirmations >= numConfirmationsRequired,
            "Number of confirmations too low"
        );

        uint _newNumConfirmations = abi.decode(proposal.proposalData, (uint));
        numConfirmationsRequired = _newNumConfirmations;
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
    }

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

        require(!_imHere, "called ImHere function");
        require(_oldOwner == msg.sender, "You are not the old owner");
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
}