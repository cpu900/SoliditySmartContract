// ---------------------------------------------------
// Author: Alexander Tofer @ https://github.com/cpu900/SoliditySmartContract
// Date: 2025-01-09
// Course@School: DV2632: Trusted Systems @ BTH.se 
// ---------------------------------------------------
// This is a crowdfunding contract where users can contribute ETH to reach the set target goal.
// (Be careful!) Only the contract creator (master) can withdraw the funds once the goal is met. 
// ---------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BTH Auction Advanced Smart Contracts
/// @notice This contract uses an auction system where bidders can place and withdraw bids
contract Auction {

    /// *** VARIBLES ***
    address public master; /// @dev Master address that controls the auction
    address public topAddress; /// Address of the current highest bidder
    uint256 public topBid; /// Current highest bid amount in wei
    bool public hasEnded; /// indicating if the auction has concluded
    mapping(address => uint256) public bids; /// Mapping to track withdrawable bids for each address

    /// *** EVENTS ***
    event NewBid(address indexed bidder, uint256 amount); /// Emitted when a new bid is placed
    event CancelBid(address indexed bidder, uint256 amount); /// Emitted when a bid is cancelled and withdrawn
    event AuctionEnded(address winner, uint256 amount); /// Emitted when the auction ends

    /// Check for functions only allowd to be called by master
    modifier onlyMaster() {
        require(msg.sender == master, "Only master can call this function");
        _;
    }

    /// Check that the auction is still active
    modifier auctionActive() {
        require(!hasEnded, "Auction has already ended");
        _;
    }

    /// @dev Sets master of the contract to be the creater.
    constructor() {
        master = msg.sender;
    }

    /// @notice Allows bidders to place a new bid
    /// @dev Implements bid verification and updates state
    function placeBid() external payable auctionActive {
        require(msg.value > 0, "Place a bid largher than zero, please!");
        require(msg.value > topBid, "Your bid must be higher than top bid!");

        address previousAddress = topAddress;
        uint256 previousBid = topBid;

        topBid = msg.value;
        topAddress = msg.sender;
        
        if (previousAddress != address(0)) {
            bids[previousAddress] = previousBid;
        }

        emit NewBid(msg.sender, msg.value);
    }

    /// @notice Allows a bidder to withdraw their outbid amounts
    /// @dev Implements checks and protection
    function withdrawBid() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No bid available to withdraw!");

        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit CancelBid(msg.sender, amount);
    }

    /// @notice Ends the auction and transfers the winning bid to master
    /// @dev Only master can call this!
    function endAuction() external onlyMaster auctionActive {
        hasEnded = true;
        emit AuctionEnded(topAddress, topBid);
        
        (bool success, ) = payable(master).call{value: topBid}("");
        require(success, "Transfer failed");
    }

    /// @notice Returns the current balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the bid amount to the bidders address
    function getWithdrawableBid(address bidder) public view returns (uint256) {
        return bids[bidder];
    }
}