// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Voting is Ownable {
    /**
    *   Variables
    */

    enum WorkflowStatus {RegisteringVoters,ProposalsRegistrationStarted,ProposalsRegistrationEnded,VotingSessionStarted,VotingSessionEnded,VotesTallied}
    WorkflowStatus public status;
    uint winningProposalId;
    uint[] equalityProposalsId;

    /**
    *   Struct
    */

    struct Voter {
        bool isRegistered;          // si le votant est sur la whiteliste
        bool hasVoted;              // si le participant à voté
        uint256 votedProposalId;    // ID de proposition du participant (une seul proposition par session de vote)
    }

    struct Proposal {
        string description;         // description de la proposition
        uint256 voteCount;          // score du vote 
    }

    struct VoteData {
        address voter;              // adresse du votant
        uint toVoteFor;             // vote du votant
    }

    // creation du mapping pour les votants
    mapping (address => Voter) public voters;
    // creation du tableau des propositions (index proposals = votedProposalId);
    Proposal[] public proposals;
    // creation du tableau des donées du vote;
    VoteData[] public voteDatas;

    /**
    *   Events
    */

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    /**
    *   Modifiers
    */

    modifier isRegistrationStarted() {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Registration of proposals has not yet started");
        _;
    }

    modifier isVotingSessionStarted() {
        require(status == WorkflowStatus.VotingSessionStarted, "The voting session has not yet started");
        _;
    }

    modifier isWhitelisted() {
        require(voters[msg.sender].isRegistered, "You are not on the white list");
        _;
    }

    modifier proposed() {
        require(voters[msg.sender].votedProposalId <= 0, "You have already made a proposal");
        _;
    }

    modifier hasVoted() {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }
    
    /**
    *   Functions
    */

    // L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function setWhitelist(address[] calldata _address) public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.VotesTallied, WorkflowStatus.RegisteringVoters);
        status = WorkflowStatus.RegisteringVoters;
        for (uint i = 0; i < _address.length; i++) {
            voters[_address[i]].isRegistered = true;
            emit VoterRegistered(_address[i]);
        }
    }

    // L'administrateur du vote commence la session d'enregistrement de la proposition.
    function ProposalsRegistrationStarted() public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        status = WorkflowStatus.ProposalsRegistrationStarted;
    }

    //* Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    function recordProposalsRegistration(string calldata _proposal) public isWhitelisted isRegistrationStarted proposed {
        proposals.push(Proposal(_proposal, 0));
        voters[msg.sender].votedProposalId = proposals.length;
        emit ProposalRegistered(proposals.length);
    }

    // L'administrateur de vote met fin à la session d'enregistrement des propositions.
    function ProposalsRegistrationEnded() public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        status = WorkflowStatus.ProposalsRegistrationEnded;
    }

    // L'administrateur du vote commence la session de vote.
    function VotingSessionStarted() public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        status = WorkflowStatus.VotingSessionStarted;
    }

    //* Les électeurs inscrits votent pour leur proposition préférée.
    function recordVotingSession(uint _voting) public isWhitelisted isVotingSessionStarted hasVoted {
        for (uint i = 0; i <= proposals.length; i++) {
            if (_voting == i) {
                proposals[i].voteCount += 1;
                voters[msg.sender].hasVoted = true;
                voteDatas.push(VoteData(msg.sender, _voting));
                emit Voted(msg.sender, _voting);
            }         
        }
    }

    // L'administrateur du vote met fin à la session de vote.
    function VotingSessionEnded() public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        status = WorkflowStatus.VotingSessionEnded;
    }

    // L'administrateur du vote comptabilise les votes. (Bonus =  gestion des égalités) 
    function VotesTallied() public onlyOwner {
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        status = WorkflowStatus.VotesTallied;
        uint value;
        uint bestValue;
        uint IdBestValue;
        delete equalityProposalsId;
        for (uint256 i = 0; i < proposals.length; i++) {
            value = proposals[i].voteCount;
            if (bestValue < value) {
                bestValue = proposals[i].voteCount;
                IdBestValue = i;
            } else if (bestValue == value) {
                equalityProposalsId.push(i);
            }
        }
        equalityProposalsId.push(IdBestValue);
        if(equalityProposalsId.length >= 2) {
            proposals.push(Proposal("Equality in the vote ! The vote is null !",0));
            winningProposalId = proposals.length - 1;
        } else {
            winningProposalId = IdBestValue;
        }
    }

    // Tout le monde peut vérifier les derniers détails de la proposition gagnante.
    function getWinner() public view returns(string memory) { 
        return proposals[winningProposalId].description;
    }

    // L'administrateur du vote supprime la liste blanche, le tableau des propositions et le potentiel tableau des égalites, en vue d'un prochain vote.
    function resetDataVoting(address[] calldata _address) public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            delete voters[_address[i]];
        }
        delete voteDatas;
        delete proposals;
        delete equalityProposalsId;
    }

    // Tous les participants peuvent vérifier les données du vote (quelle adresse à voter pour quelle proposition).
    function getVoteData() public isWhitelisted view returns(VoteData[] memory) { 
        VoteData[] memory data = new VoteData[](voteDatas.length);
        for (uint i = 0; i < voteDatas.length; i++) {
            VoteData storage voteData = voteDatas[i];
            data[i] = voteData;
        }
        return data;
    }

    // Tous les participants peuvent vérifier le tableau des ID des propositions arrivé à égalité.
    function getEquality() public isWhitelisted view returns(uint[] memory) { 
        return equalityProposalsId;
    }

    // Petit override de la fonction hérité de Ownable pour éviter les accidents.
    function renounceOwnership() public override view onlyOwner {
        revert("can't renounceOwnership here");
    }
}