// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployRaffle is Script{
    function run() external returns(Raffle){
        HelperConfig helperConfig = new HelperConfig();
        (uint256 ticketprice,
        uint256 interval,
        address vrfCord,
        bytes32 gasLane, 
        uint64 subId, 
        uint32 gasLimit) = helperConfig.activeNetworkConfig();
        
    }
}