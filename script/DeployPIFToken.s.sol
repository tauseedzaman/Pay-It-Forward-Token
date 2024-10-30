// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PIFToken} from "../src/PIFToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployPIFToken is Script {
    function run() external returns (PIFToken) {
        vm.startBroadcast(); //for start broadcasting events
        PIFToken _PIFToken = new PIFToken();
        vm.stopBroadcast(); // stop broadcasting events
        return _PIFToken;
    }
}
