# cyfrin-advanced-foundry-dao

This project is a section of the
[Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-full-course-cu?tab=readme-ov-file#advanced-foundry-section-7-foundry-dao--governance).

1. The project implements a contract controlled by a DAO.
2. Every transaction that the DAO wants to send has to be voted on.
3. ERC20 tokens are used for voting.

_Please note: ERC20 based voting is not always recommended, and exploring other forms of governance is encouraged
like reputation based or "skin-in-the-game" based. We use ERC20 for the purpose of learning._

## Implementation details

_[Openzeppelin Wizzard](https://wizard.openzeppelin.com) was used to generate `GovToken` and `MyGovernor`._

The contract to be goverened by our DAO is `Box`. The storage of an integer value is governed.
Only our DAO may change this integer value, by making the `store` function callable only by the contract's owner.

`GovToken` is our ERC20 governance token. It allows people to sign transactions without sending them, such that someone else can send it, paying for the gas.
It is "Compound-like" in how it implements voting and delegation. It does a number of import things such as:

* Keeps a checkpoint history of each account's voting power. Using snapshots of voting power is important, as assessing realtime voting power is susceptible to exploitation!
  * Any time a token is bought, or transferred checkpoints are typically updated in a mapping with the user addresses involved
* Allows the delegation of voting power to another entity while retaining possession of the tokens

`MyGovernor` is the governor contract. It has a few inherinences from openzeppelin contrats:

* `Governor`: DAO members can submit proposals via this contract. It tracks proposals via the `_proposals` mapping. Each proposal's state is tracked
* `Governor`: The `_castVote` function references the proposal, determines a voting weight, then adds the votes to an internal count of votes for that proposal, finally emits an event
* `Governor`: Executes the proposals if they are passed
* `GovernorVotes`: Extracts voting weight from the ERC20 tokens used for a protocols governance
* `GovernorSettings`: Allows configuration of things like voting delay, voting period and proposalThreshhold to the protocol
* `GovernorCountingSimple`: Implements a simplied vote counting mechanism by which each proposal is assigned a `ProposalVote` struct in which `forVotes`, `againstVotes` and `abstainVotes` are tallied
* `GovernorVotesQuorumFraction`: Assists in token voting weight extraction
* `GovernorTimelockControl`: Binds the execution process to an instance of `TimelockController`. This adds a delay, enforced by the `TimelockController` to all successful proposals (in addition to the voting duration).

On deployment our DAO takes a governance token and a `TimelockController` as well as configure a bunch of the settings.

`TimeLock` is the timelocked controller of the governor contract and the owner of `Box`, the governed contract.
When set as the owner of an `Ownable` smart contract, it enforces a timelock on all `onlyOwner` maintenance operations.
This gives time for users of the controlled contract to exit before a potentially dangerous maintenance operation is applied.
