// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
/**
 Creating Raffle contract using chianlink vrf2
 */

// create event after every storage update 
contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEth();
    error Raffle_TransferFail();
    error Raffle_NotOpen();
    
    enum WinnerState{OPEN, CALCULATING}

    uint16 private constant REQUEST_CONFIRM = 3;
    uint32 private constant WORDS = 1;

    uint256 private immutable i_TICKETPRICE;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCord;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subId;
    uint32 private immutable i_gasLimit;

    WinnerState private s_winnerState;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    
    constructor(uint256 ticketprice, uint256 interval, address vrfCord, bytes32 gasLane, uint64 subId, uint32 gasLimit)
    VRFConsumerBaseV2(vrfCord){
        i_TICKETPRICE = ticketprice;
        i_interval = interval;
        i_vrfCord = VRFCoordinatorV2Interface(vrfCord);
        i_gasLane = gasLane;
        i_subId = subId;
        i_gasLimit = gasLimit;
        s_winnerState = WinnerState.OPEN;
    }

    function getTicketPrice() public view returns(uint256) {
        return i_TICKETPRICE;
    }
    function enter() external payable{
        if(msg.value < i_TICKETPRICE){
            revert Raffle__NotEnoughEth();
        }
        if (s_winnerState != WinnerState.OPEN){
            revert Raffle_NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle((msg.sender));
    }


    function pickWinner() external {
        
        if (block.timestamp - s_lastTimeStamp > i_interval){
            revert();
        }
        uint256 requestId = i_vrfCord.requestRandomWords(
            i_gasLane, // gas lane
            i_subId, //id with link
            REQUEST_CONFIRM, 
            i_gasLimit,
            WORDS);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        (bool success,) = winner.call{value: address(this).balance}("");
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        
        if (!success){
            revert Raffle_TransferFail();
        }
        s_winnerState = WinnerState.OPEN;
        emit WinnerPicked(winner);
    
    }
}

