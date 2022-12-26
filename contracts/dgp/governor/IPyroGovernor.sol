// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../Budget.sol";
import "../DGP.sol";
import "../Governance.sol";

interface IPyroGovernor {
    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) external;

    function enroll() external;

    function unenroll(bool force) external;

    function ping() external;

    function addProposal(DGP.ProposalType proposalType, address proposalAddress)
        external;

    function voteForProposal(uint8 proposalId, Budget.Vote vote) external;

    function startProposal(
        string memory title,
        string memory description,
        string memory url,
        uint256 requested,
        uint8 duration
    ) external payable;

    function withdraw() external;
}
