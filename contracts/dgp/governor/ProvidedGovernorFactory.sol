// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../Budget.sol";
import "../DGP.sol";
import "../Governance.sol";
import "./IGovernorFactory.sol";
import "./ProvidedGovernor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProvidedGovernorFactory is IGovernorFactory, Ownable {
    DGP public immutable dgp;
    Governance public immutable governance;
    Budget public immutable budget;

    mapping(uint256 => address) public governors;
    mapping(uint256 => address) public providers;

    uint8 public count;

    modifier onlyProvider(uint8 governor) {
        require(
            msg.sender == providers[governor],
            "ProvidedGovernorFactory: caller is not the provider"
        );
        _;
    }

    constructor(
        address dgpAddress,
        address governanceAddress,
        address budgetAddress
    ) {
        dgp = DGP(dgpAddress);
        governance = Governance(governanceAddress);
        budget = Budget(budgetAddress);
    }

    fallback() external payable {}

    receive() external payable {}

    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public override onlyOwner {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "ProvidedGovernorFactory: Tx failed");
    }

    function createGovernor() public payable override {
        uint256 collateral = dgp.getGovernanceCollateral()[0];
        require(
            msg.value == collateral,
            "ProvidedGovernorFactory: invalid value"
        );
        governors[count] = address(
            new ProvidedGovernor(
                address(dgp),
                address(governance),
                address(budget)
            )
        );
        providers[count] = msg.sender;
        enroll(count);
        count++;
    }

    function enroll(uint8 id) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        uint256 collateral = dgp.getGovernanceCollateral()[0];
        require(
            payable(address(this)).balance >= collateral,
            "ProvidedGovernorFactory: Insufficient balance to enroll"
        );
        (bool funded, ) = payable(governors[id]).call{value: collateral}("");
        require(funded, "ProvidedGovernorFactory: Failed to fund governor");
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.enroll();
    }

    function unenroll(uint8 id, bool force) public override onlyProvider(id) {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        governors[id] = address(0x0);
        providers[id] = address(0x0);
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.unenroll(force);
    }

    function ping(uint8 id) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.ping();
    }

    function addProposal(
        uint8 id,
        DGP.ProposalType proposalType,
        address proposalAddress
    ) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.addProposal(proposalType, proposalAddress);
    }

    function voteForProposal(
        uint8 id,
        uint8 proposalId,
        Budget.Vote vote
    ) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.voteForProposal(proposalId, vote);
    }

    function withdraw() public override onlyOwner {
        require(
            payable(address(this)).balance > 0,
            "ProvidedGovernorFactory: No funds to withdraw"
        );
        (bool success, ) = payable(owner()).call{
            value: payable(address(this)).balance
        }("");
        require(success, "ProvidedGovernorFactory: Withdraw failed");
    }

    function withdraw(uint8 id) public override onlyProvider(id) {
        require(
            governors[id] != address(0x0),
            "ProvidedGovernorFactory: Governor does not exist"
        );
        ProvidedGovernor governor = ProvidedGovernor(payable(governors[id]));
        governor.withdraw();
    }
}