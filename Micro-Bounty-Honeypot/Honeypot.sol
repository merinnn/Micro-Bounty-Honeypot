// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Honeypot {
    mapping(address => uint256) public balances;

    // Users deposit testnet tokens into the honeypot bounty pool
    function deposit() public payable {
        require(msg.value > 0, "Must deposit some tokens");
        balances[msg.sender] += msg.value;
    }

    //  VULNERABLE FUNCTION: Sends funds before updating the state
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Insufficient balance");

        // 1. Interaction: Sends funds to the caller's contract/wallet
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        // 2. State Update: Happens too late!
        balances[msg.sender] = 0;
    }

    // Helper to see how many tokens are left in the game pool
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
