// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from  "../test/Mocks/Link.t.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        uint256 ticketprice;
        uint256 interval;
        address vrfCord;
        bytes32 gasLane; 
        uint64 subId; 
        uint32 gasLimit;
        address link;
    }

    NetworkConfig public currentNetworkConfig;
    constructor (){
        if (block.chainid == 11155111){
            currentNetworkConfig = getSepoliaEthConfig();
        }
        else{
            currentNetworkConfig = getAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({
            ticketprice: 0.001 ether,
            interval: 30,
            vrfCord: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 0,
            gasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory){
        if(currentNetworkConfig.vrfCord != address(0)){
            return currentNetworkConfig;
        }

        uint96 baseFee =0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock  vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            ticketprice: 0.001 ether,
            interval: 30,
            vrfCord: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 0,
            gasLimit: 500000,
            link: address(link)
        });
    }
}