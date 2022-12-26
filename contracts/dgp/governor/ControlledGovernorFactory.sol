// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../Budget.sol";
import "../DGP.sol";
import "../Governance.sol";
import "./IGovernorFactory.sol";
import "./ControlledGovernor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ControlledGovernorFactory is IGovernorFactory, Ownable {
    DGP public immutable dgp;
    Governance public immutable governance;
    Budget public immutable budget;

    mapping(uint8 => address) public governors;

    uint8 public count;

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
        require(success, "GovernorFactory: Tx failed");
    }

    function createGovernor() public payable override onlyOwner {
        governors[count] = address(
            new ControlledGovernor(
                address(dgp),
                address(governance),
                address(budget)
            )
        );
        uint256 collateral = dgp.getGovernanceCollateral()[0];
        if (payable(address(this)).balance >= collateral) {
            enroll(count);
        }
        count++;
    }

    function enroll(uint8 id) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        uint256 collateral = dgp.getGovernanceCollateral()[0];
        require(
            payable(address(this)).balance >= collateral,
            "GovernorFactory: Insufficient balance to enroll"
        );
        (bool funded, ) = payable(governors[id]).call{value: collateral}("");
        require(funded, "GovernorFactory: Failed to fund governor");
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.enroll();
    }

    function unenroll(uint8 id, bool force) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.unenroll(force);
    }

    function ping(uint8 id) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.ping();
    }

    function addProposal(
        uint8 id,
        DGP.ProposalType proposalType,
        address proposalAddress
    ) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.addProposal(proposalType, proposalAddress);
    }

    function voteForProposal(
        uint8 id,
        uint8 proposalId,
        Budget.Vote vote
    ) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.voteForProposal(proposalId, vote);
    }

    function withdraw() public override onlyOwner {
        require(
            payable(address(this)).balance > 0,
            "GovernorFactory: No funds to withdraw"
        );
        (bool success, ) = payable(owner()).call{
            value: payable(address(this)).balance
        }("");
        require(success, "GovernorFactory: Withdraw failed");
    }

    function withdraw(uint8 id) public override onlyOwner {
        require(
            governors[id] != address(0x0),
            "GovernorFactory: Governor does not exist"
        );
        ControlledGovernor governor = ControlledGovernor(
            payable(governors[id])
        );
        governor.withdraw();
    }
}
