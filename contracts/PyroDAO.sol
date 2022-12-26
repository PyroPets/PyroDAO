// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./dgp/Budget.sol";
import "./dgp/DGP.sol";
import "./dgp/Governance.sol";
import "./token/PyroDAOToken.sol";
import "./vault/PyroVaultFactory.sol";
import "./dgp/governor/ControlledGovernorFactory.sol";
import "./dgp/governor/ProvidedGovernorFactory.sol";
import "@pyropets/pyropets-contracts/contracts/PyroBase.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract PyroDAO is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    PyroBase public immutable base;
    DGP public immutable dgp;
    Governance public immutable governance;
    Budget public immutable budget;
    ControlledGovernorFactory public controlledGovernorFactory;
    ProvidedGovernorFactory public providedGovernorFactory;
    PyroVaultFactory public vaultFactory;

    constructor(
        address pyroBase,
        address dgpAddress,
        address governanceAddress,
        address budgetAddress
    )
        Governor("Pyro DAO")
        GovernorSettings(
            15, /* 15 block */
            13440, /* 2 week */
            1
        )
        GovernorVotes(new PyroDAOToken(pyroBase))
        GovernorVotesQuorumFraction(51)
    {
        base = PyroBase(pyroBase);
        dgp = DGP(dgpAddress);
        governance = Governance(governanceAddress);
        budget = Budget(budgetAddress);
        controlledGovernorFactory = new ControlledGovernorFactory(
            dgpAddress,
            governanceAddress,
            budgetAddress
        );
        providedGovernorFactory = new ProvidedGovernorFactory(
            dgpAddress,
            governanceAddress,
            budgetAddress
        );
        vaultFactory = new PyroVaultFactory();
    }

    function reclaimVote(uint256 tokenId) public {
        PyroDAOToken(address(this.token())).reclaim(msg.sender, tokenId);
    }

    function createControlledGovernor() public onlyGovernance {
        controlledGovernorFactory.createGovernor();
    }

    function createProvidedGovernor() public payable {
        require(
            msg.value == dgp.getGovernanceCollateral()[0],
            "PyroDAO: Collateral must be exact"
        );
        providedGovernorFactory.createGovernor{value: msg.value}();
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}