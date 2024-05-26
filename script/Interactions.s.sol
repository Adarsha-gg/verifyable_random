// SPDX-license-Identifier: MIT

pragma solidity ^0.8.16;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from  "../test/Mocks/Link.t.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSub is Script{
    function createSubUserConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfCord, , , ,) = helperConfig.currentNetworkConfig();
        return createSub(vrfCord);
        
    }

    function createSub(address _vrfCord) public returns(uint64){
        console.log("Creating sub on chainid", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(_vrfCord).createSubscription();
        vm.stopBroadcast();
        console.log("Sub id is", subId);
        return subId;
    }

    function run() external returns(uint64){
        return createSubUserConfig();
    }
}

contract FundSub is Script{
    uint96 public constant MONI = 10 ether;

    function FundSubUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfCord, , uint64 subId, , address link) = helperConfig.currentNetworkConfig();
        fundSub(vrfCord, subId, link);
    
    }

    function fundSub(address _vrfCord, uint64 _subId, address _link) public {
        console.log ("FUnding sub", _subId);
        console.log("Using vrfCoordinator", _vrfCord);
        console.log("On chainId: " , block.chainid);
        if (block.chainid == 3133){
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCord).fundSubscription(_subId, MONI);
            vm.stopBroadcast();
        }
        else{
            vm.startBroadcast();
            LinkToken(_link).transferAndCall(_vrfCord, MONI, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function run() external{
        FundSubUsingConfig();
    }   
}

contract AddConsumer is Script{

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfCord, , uint64 subId, ,) = helperConfig.currentNetworkConfig();
        addConsumer(raffle, vrfCord, subId);

    }

    function addConsumer(address raffle, address vrfCord, uint64 subId) public  {
        console.log("Adding consumer");
        console.log("Vrf COrd: ", vrfCord);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCord).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}