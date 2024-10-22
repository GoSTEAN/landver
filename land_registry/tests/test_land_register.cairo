use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
use starknet::ContractAddress;

use land_registry::land_register::{ILandRegistryDispatcher, ILandRegistryDispatcherTrait};


use land_registry::interface::LandUse;

fn deploy(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_can_register_land() {
    let contract_address = deploy("LandRegistry");

    // Get an instance of the deployed Counter contract
    let land_register_dispatcher = ILandRegistryDispatcher { contract_address };

    // Set up test data
    let land1 = land_register_dispatcher.register_land('Bar', 23, 4);
    assert(land., '');
}
