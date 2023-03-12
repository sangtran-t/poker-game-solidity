// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PokerGame {
    uint public pot;
    uint public dealerHandValue;
    uint public playerHandValue;
    uint public totalPlayers;

    address public dealer;
    address public player;
    
    // Initialize game
    constructor() payable {
        require(msg.value > 0, "Please provide some ether to start the game.");
        pot = msg.value;
        dealer = msg.sender;
    }

    // Allow players to add ether to the pot
    function joinGame() public payable {
        require(totalPlayers <= 2, "Maximum players!" );
        require(msg.sender != dealer, "Dealer can't join the game!");
        require(msg.value >= 10**18, "Please provide some ether to start the game.");
        pot += msg.value;
        player = msg.sender;
        totalPlayers += 1;
    }
    
    // Deal cards
    function deal() public {
        require(msg.sender == dealer, "Only the dealer can deal the cards.");
        require(player == address(0), "Cards have already been dealt.");
        player = msg.sender;
        
        // Generate random cards
        uint256 dealerCard1 = uint256(keccak256(abi.encodePacked(block.timestamp, dealer))) % 13 + 2;
        uint256 dealerCard2 = uint256(keccak256(abi.encodePacked(block.timestamp, dealer, dealerCard1))) % 13 + 2;
        uint256 dealerCard3 = uint256(keccak256(abi.encodePacked(block.timestamp, dealer, dealerCard1, dealerCard2))) % 13 + 2;
        uint256 playerCard1 = uint256(keccak256(abi.encodePacked(block.timestamp, player))) % 13 + 2;
        uint256 playerCard2 = uint256(keccak256(abi.encodePacked(block.timestamp, player, playerCard1))) % 13 + 2;
        uint256 playerCard3 = uint256(keccak256(abi.encodePacked(block.timestamp, player, playerCard1, playerCard2))) % 13 + 2;
        
        // Calculate hand values
        dealerHandValue = calculateHandValue(dealerCard1, dealerCard2, dealerCard3);
        playerHandValue = calculateHandValue(playerCard1, playerCard2, playerCard3);
    }
    
    // Calculate hand value
    function calculateHandValue(uint256 card1, uint256 card2, uint256 card3) private pure returns (uint256) {
        uint256 sum = card1 + card2 + card3;
        if (sum >= 33) {
            return 0;
        } else if (card1 == card2 && card2 == card3) {
            return 30;
        } else if (card1 == card2 || card2 == card3 || card1 == card3) {
            return 10;
        } else {
            return sum % 10;
        }
    }
    
    // Determine winner
    function determineWinner() public {
        require(msg.sender == player, "Only the player can determine the winner.");
        require(playerHandValue != 0 && dealerHandValue != 0, "Cards have not been dealt yet.");
        
        // Determine winner
        if (playerHandValue > dealerHandValue) {
            payable(player).transfer(pot);
        } else if (dealerHandValue > playerHandValue) {
            payable(dealer).transfer(pot);
        } else {
            payable(player).transfer(pot / 2);
            payable(dealer).transfer(pot / 2);
        }
        
        // Reset game
        pot = 0;
        dealerHandValue = 0;
        playerHandValue = 0;
        dealer = address(0);
        player = address(0);
    }
}