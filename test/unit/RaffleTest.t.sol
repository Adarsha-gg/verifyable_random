// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
    
    modifier raffleEnteredAndTimePassed() {
        raffle.enter{value: MONI}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testUpkeepRaffleStateInEvents() public raffleEnteredAndTimePassed() {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        
        assert(uint256(requestId) > 0);
    }

    function testRandomWordsCalledAfterUpkeep(uint256 randomReqId) public raffleEnteredAndTimePassed() {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCord).fulfillRandomWords(randomReqId,address(raffle));
    }

    function testRandomWordsDoesWhatItsSupposedToDo() public raffleEnteredAndTimePassed(){

        uint256 Entrants = 5;
        uint256 index = 1;
        for(uint256 i = index; i < index+ Entrants; i++)
        {
            address player = address(uint160(i));
            hoax(player, 1);
            raffle.enter{value: ticketprice}();
        }

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        
        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCord).fulfillRandomWords(uint256(requestId), address(raffle));
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
        assert(raffle.getLengthOfPlayers() == 0);
    }
}