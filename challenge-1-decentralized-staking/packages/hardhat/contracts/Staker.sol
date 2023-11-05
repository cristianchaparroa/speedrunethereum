// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  // It track the individual balances
  mapping (address => uint256) public balances;

  event Stake(address, uint256);

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw = true;

  bool public openForStake = true;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable {
        require(timeLeft() > 0, "The staking is closed. You can't longer contribute money");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public payable notCompleted {
    require(block.timestamp > deadline, "The staking still open. You can't transfer staking funds until the funds and deadline is reached");
    if (isThresholdReached()) {
        exampleExternalContract.complete{value: address(this).balance}();
        openForWithdraw = false;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notCompleted {
     require(!isThresholdReached(), "The threshold was reached. You can't withdraw"); 
     require(timeLeft() <= 0 , "The deadline still open");
     require(openForWithdraw, "The staking has been already transferred.");

     uint256 amount = balances[msg.sender];
     require(amount > 0, "You didn't contribute to the Staking.");

     (bool response, /*bytes data*/) =  msg.sender.call{value: amount}("");
     require(response, "it wasn't possible transferring back the moeney");

     balances[msg.sender] = 0;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp < deadline) {
        return deadline - block.timestamp;
    }
    return 0;
  }

  function isThresholdReached() private view returns(bool) {
    return address(this).balance >= threshold;
  }

  modifier notCompleted() {
    bool isCompleted = exampleExternalContract.completed();
    require(!isCompleted);
    _;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
