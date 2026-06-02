# 🎯 Micro-Bounty Honeypot: Web3 Reentrancy Exploit Lab

## 🔬 Project Overview
This repository contains an offensive/defensive blockchain security laboratory built to demonstrate the real-world execution and mitigation of a **Reentrancy Vulnerability** (the infamous vector behind the historic Ethereum DAO Hack). 

The environment simulates a classic Capture-The-Flag (CTF) puzzle: a vulnerable vault holding a target testnet bounty pool, alongside a malicious proxy contract engineered to exploit a broken state execution flow.

---

## ⚔️ The Vulnerability: Insecure Interaction Pattern
The core exploit targets the `withdraw()` function inside `Honeypot.sol`. The contract processes payments via a low-level external call *before* updating its internal state balance ledger:

1. **Check:** Evaluates if the caller has a credit balance.
2. **Interaction:** Transfers raw Ether via `.call{value: balance}("")`. 
3. **Effect:** Updates internal ledger states (`balances[msg.sender] = 0;`).

Because the external transfer occurs before the state update, an attacking contract can intercept the control stream via its `receive()` fallback function and recursively trigger `withdraw()`, draining the vault completely.

---

## 🕹️ Lab Simulation & Proof of Concept

### Step 1: Target Deployment & Funding
The target contract (`Honeypot.sol`) is instantiated on a local virtual machine sandbox environment. An external user interacts with the protocol via `deposit()` to load a **5 Ether** bounty pool.

*Current Contract State Verification (Showing 5 ETH balance):*
![Target Vault Funded](https://raw.githubusercontent.com/merinnn/Micro-Bounty-Honeypot/main/Screenshot202026-06-0220193500.png)

### Step 2: Exploit Payload Delivery
The malicious agent contract (`Attacker.sol`) is deployed by supplying the target Honeypot's contract address to its constructor logic. The exploit is executed by calling `launchAttack()` with a starter payload of **1 Ether** to clear the initial contract constraints.

*Exploit Execution Parameters (Sending 1 ETH via launchAttack):*
![Exploit Initiation](https://raw.githubusercontent.com/merinnn/Micro-Bounty-Honeypot/main/Screenshot202026-06-0220194631.png)

### Step 3: Draining the Vault Storage
The recursive fallback structure intercepts the incoming funds mid-transaction, looping execution back into the vault before the state balance can be zeroed out. The exploit stops once the Honeypot's overall network balance falls below the threshold.

*Post-Exploit Target State Verification (Honeypot balance at 0):*
![Honeypot Completely Drained](https://raw.githubusercontent.com/merinnn/Micro-Bounty-Honeypot/main/Screenshot202026-06-0220194710.png)

### Step 4: Asset Recovery
With the vault emptied, the attacker securely invokes `withdrawStolenFunds()`, routing the entire bounty pool out of the malicious proxy layer directly into the developer's controlled testing address.

*Exploit Cleanup Status (Clean transaction log):*
![Stolen Assets Cleared](https://raw.githubusercontent.com/merinnn/Micro-Bounty-Honeypot/main/Screenshot202026-06-0220194906.png)

---

## 🛡️ Remediation Strategies

To secure this framework against reentrancy loops, two distinct defensive patterns can be applied:

### A. Checks-Effects-Interactions Pattern (Recommended)
Refactor the code logic to guarantee all internal state variables are updated completely *before* initiating any external contract calls:

```solidity
function withdraw() public {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "Insufficient balance");

    // 1. Effect: Clear state balance BEFORE the interaction
    balances[msg.sender] = 0;

    // 2. Interaction: Hand over control stream safely
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Transfer failed");
}
