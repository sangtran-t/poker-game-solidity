// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ThreeCardPoker {
  uint public pot;
  address public dealer;
  address public player;
  address public winner;
  uint[] public dealerHand;
  uint[] public playerHand;
  uint public playerBet;

  // The current state of the game
  enum GameState {
    NotStarted,
    Betting,
    Dealing,
    Showdown
  }
  GameState public state = GameState.NotStarted;

  // events
  event GameStarted(address dealer, uint pot);
  event BettingStarted();
  event DealingStarted();
  event ShowdownStarted();

  constructor(uint _pot) {
    // cost of the game in Ether
    pot += _pot * (1 ether);
    dealer = msg.sender;
  }

  // start a game
  function startGame() external payable {
    require(msg.sender == dealer, "Only the dealer can start the game");
    require(state == GameState.NotStarted, "Game already started");
    require(msg.value == pot, "Incorrect game cost");

    state = GameState.Betting;
    emit GameStarted(msg.sender, msg.value);
  }

  // place a bet
  function joinGame() external payable {
    require(msg.sender != dealer, "Dealer cannot join the game");
    require(player == address(0), "Cannot join the game right now");
    require(state == GameState.Betting, "Cannot place bet at this time");
    require(msg.value <= address(this).balance, "Cannot bet more than the pot");

    player = msg.sender;
    playerBet = msg.value;
    state = GameState.Dealing;
    emit BettingStarted();
    emit DealingStarted();
  }

  // deal cards
  function dealCards() external {
    require(state == GameState.Dealing, "Cannot deal cards at this time");
    playerHand = _generateCards();
    dealerHand = _generateCards();
    state = GameState.Showdown;
    emit DealingStarted();
    emit ShowdownStarted();
  }

  // determine the winner
  function determineWinner() external {
    require(
      state == GameState.Showdown,
      "Cannot determine winner at this time"
    );

    // Determine the winner based on the hands
    uint playerHandValue = _getHandValue(playerHand);
    uint dealerHandValue = _getHandValue(dealerHand);
    if (playerHandValue > dealerHandValue) {
      // Player wins
      payable(msg.sender).transfer(playerBet * 2);
    } else if (playerHandValue == dealerHandValue) {
      payable(msg.sender).transfer(playerBet);
    } else {
      // Dealer wins
    }
    // Reset the game state
    playerHand = new uint[](0);
    dealerHand = new uint[](0);
    playerBet = 0;
    state = GameState.NotStarted;
  }

  // dealer can withdraw balance from the contract
  function withdraw() external {
    require(
      state == GameState.NotStarted,
      "Cannot withdraw while game is in progress"
    );
    payable(msg.sender).transfer(address(this).balance);
  }

  function claim() external {
    require(state == GameState.NotStarted, "Cannot claim right now!");
    require(msg.sender == winner, "You are not the winner!");
    payable(msg.sender).transfer(address(this).balance);
  }

  // generate random cards
  function _generateCards() private view returns (uint[] memory) {
    uint[] memory cards = new uint[](3);
    for (uint i = 0; i < 3; i++) {
      cards[i] =
        (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) %
          13) +
        1;
    }
    return cards;
  }

  function _getHandValue(uint[] memory hand) private pure returns (uint) {
    uint value = 0;
    uint numAces = 0;
    for (uint i = 0; i < 3; i++) {
      uint cardValue = hand[i];
      if (cardValue > 10) {
        // J, Q, K - value is 10
        cardValue = 10;
      } else if (cardValue == 1) {
        // A - value is 11
        cardValue = 11;
        numAces++;
      }
      value += cardValue;
    }
    // Handle aces
    while (numAces > 0 && value > 21) {
      value -= 10;
      numAces--;
    }
    return value;
  }
}
