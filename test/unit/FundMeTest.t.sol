// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 10 ETH
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        // This is where we can set up the test environment
        // For example, we can deploy contracts or set initial states
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ETH
    }

    function testMinimumUSD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOnwerIsMsgSender() public view {
        assertEq(fundMe.getOnwer(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        // This test checks if the price feed version is correct
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // This makes the next call from the USER address
        fundMe.fund{value: SEND_VALUE}();

        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // This makes the next call from the USER address
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); // This makes the next call from the USER address
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER); // This makes the next call from the USER address
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOnwer());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOnwer().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOnwer());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOnwer().balance);
    }

    function testWithdrawFromMultipleFunderCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOnwer());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOnwer().balance);
    }
}
