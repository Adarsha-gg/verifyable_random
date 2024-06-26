// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
/**
 Creating Raffle contract using chianlink vrf2
 */

// create event after every storage update 

//CHECKS EFFECTS INTERACTIONS. ( FOR MOST GAS EFFICIENCY)
contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEth();
    error Raffle__TransferFail();
    error Raffle__NotOpen();
    error Raffle__UpKeepFail(uint256 Balance, uint256 state);

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
    event RequestRaffle(uint256 indexed requestId);
    
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
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle((msg.sender));
    }

    //function for chainlink automation to call
    /* refer here: https://docs.chain.link/chainlink-automation/guides/compatible-contracts */
    function checkUpKeep(bytes memory /* checkdata */) public view returns (bool upkeepNeeded, bytes memory){
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = WinnerState.OPEN == s_winnerState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return(upkeepNeeded, "0w0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool isUpKeep,) = checkUpKeep("");
        if(!isUpKeep){
            revert Raffle__UpKeepFail(address(this).balance, uint256(s_winnerState));
        }
        s_winnerState = WinnerState.CALCULATING;
        uint256 requestId = i_vrfCord.requestRandomWords(
            i_gasLane, // gas lane
            i_subId, //id with link
            REQUEST_CONFIRM, 
            i_gasLimit,
            WORDS);
        emit RequestRaffle(requestId);    
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        (bool success,) = winner.call{value: address(this).balance}("");
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        
        if (!success){
            revert Raffle__TransferFail();
        }
        s_winnerState = WinnerState.OPEN;
        emit WinnerPicked(winner);
    }

    function getRaffleState() external returns (WinnerState) {
        return s_winnerState;
    }

    function getPlayer(uint256 index) external view returns(address){
        return s_players[index];
    }

    function getLengthOfPlayers() external view returns(uint256){
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
        
}

