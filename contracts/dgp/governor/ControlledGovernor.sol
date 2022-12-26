// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IPyroGovernor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ControlledGovernor is IPyroGovernor, Ownable {
    DGP public immutable dgp;
    Governance public immutable governance;
    Budget public immutable budget;

    constructor(
        address dgpAddress,
        address governanceAddress,
        address budgetAddress
    ) {
        dgp = DGP(dgpAddress);
        governance = Governance(governanceAddress);
        budget = Budget(budgetAddress);
    }

    fallback() external payable {
        if (
            (msg.sender == address(governance) ||
                msg.sender == address(budget)) && msg.value > 0
        ) {
            payable(owner()).call{value: msg.value}("");
        }
    }

    receive() external payable {
        if (
            (msg.sender == address(governance) ||
                msg.sender == address(budget)) && msg.value > 0
        ) {
            payable(owner()).call{value: msg.value}("");
        }
    }

    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public override onlyOwner {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "ControlledGovernor: Tx failed");
    }

    function enroll() public override onlyOwner {
        uint256 collateral = dgp.getGovernanceCollateral()[0];
        require(
            payable(address(this)).balance >= collateral,
            "ControlledGovernor: Insufficient collateral"
        );
        governance.enroll{value: collateral}();
    }

    function unenroll(bool force) public override onlyOwner {
        governance.unenroll(force);
    }

    function ping() public onlyOwner {
        governance.ping();
    }

    function addProposal(DGP.ProposalType proposalType, address proposalAddress)
        public
        override
        onlyOwner
    {
        dgp.addProposal(proposalType, proposalAddress);
    }

    function voteForProposal(uint8 proposalId, Budget.Vote vote)
        public
        override
        onlyOwner
    {
        budget.voteForProposal(proposalId, vote);
    }

    function startProposal(
        string memory title,
        string memory description,
        string memory url,
        uint256 requested,
        uint8 duration
    ) external payable {
        uint256 fee = dgp.getBudgetFee()[0];
        require(msg.value == fee, "ControlledGovernor: Invalid fee");
        budget.startProposal{value: fee}(
            title,
            description,
            url,
            requested,
            duration
        );
    }

    function withdraw() public override onlyOwner {
        require(
            payable(address(this)).balance > 0,
            "ControlledGovernor: No funds to withdraw"
        );
        (bool success, ) = payable(owner()).call{
            value: payable(address(this)).balance
        }("");
        require(success, "ControlledGovernor: Withdraw failed");
    }
}
