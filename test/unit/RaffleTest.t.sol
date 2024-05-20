// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    
    HelperConfig helperConfig;
    Raffle raffle;
    address public PLAYER = makeAddr("Player");
    uint256 public constant MONI = 100 ether;

    uint256 ticketprice;
    uint256 interval;
    address vrfCord;
    bytes32 gasLane; 
    uint64 subId; 
    uint32 gasLimit;
    address link;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            ticketprice,
         interval,
         vrfCord,
         gasLane, 
        subId,
        gasLimit,
        link
        ) = helperConfig.currentNetworkConfig();

    }

    function testRaffleOpenState() public {
        assert(raffle.getRaffleState() == Raffle.WinnerState.OPEN);
    }

    function testRaffleNotEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.enter();
    }

    function testRaffleRecord() public{
        vm.prank(PLAYER);
        vm.deal(PLAYER, MONI);
        raffle.enter{value: MONI}();
        address playerAdd = raffle.getPlayer(0);
        assert(playerAdd == PLAYER);
    }
}