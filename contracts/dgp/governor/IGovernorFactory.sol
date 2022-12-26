// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../Budget.sol";
import "../DGP.sol";
import "../Governance.sol";
import "./IPyroGovernor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGovernorFactory {
    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) external;

    function createGovernor() external payable;

    function enroll(uint8 id) external;

    function unenroll(uint8 id, bool force) external;

    function ping(uint8 id) external;

    function addProposal(
        uint8 id,
        DGP.ProposalType proposalType,
        address proposalAddress
    ) external;

    function voteForProposal(
        uint8 id,
        uint8 proposalId,
        Budget.Vote vote
    ) external;

    function withdraw() external;

    function withdraw(uint8 id) external;
}
