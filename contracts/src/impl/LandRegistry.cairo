use starknet::ContractAddress;
use models::ModelLandRegistry;

#[starknet::contract]
mod LandRegistry {
    use super::ContractAddress;
    use super::ModelLandRegistry::{Land, Event};

    #[storage]
    struct Storage {
        lands: LegacyMap<u256, Land>,
        owner_lands: LegacyMap<(ContractAddress, u256), u256>,
        owner_land_count: LegacyMap<ContractAddress, u256>,
        land_nft: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, land_nft: ContractAddress) {
        self.land_nft.write(land_nft);
    }

    #[external(v0)]
    fn register_land(
        ref self: ContractState,
        land_id: u256,
        location: felt252,
        area: u256,
        land_use: felt252,
        document_hash: felt252
    ) {
        let caller = get_caller_address();
        let new_land = Land {
            owner: caller,
            location: location,
            area: area,
            land_use: land_use,
            is_registered: true,
            is_verified: false,
            document_hash: document_hash,
            last_transaction_timestamp: get_block_timestamp(),
        };
        self.lands.write(land_id, new_land);
        
        let count = self.owner_land_count.read(caller);
        self.owner_lands.write((caller, count), land_id);
        self.owner_land_count.write(caller, count + 1);

        self.emit(Event::LandRegistered(LandRegistered {
            land_id: land_id,
            owner: caller,
            location: location,
            area: area,
            land_use: land_use,
            document_hash: document_hash,
        }));

        // Mint NFT
        ILandNFT::mint_land(
            self.land_nft.read(),
            caller,
            land_id,
            location,
            area,
            land_use,
            document_hash
        );
    }

    #[external(v0)]
    fn transfer_land(ref self: ContractState, land_id: u256, new_owner: ContractAddress) {
        let caller = get_caller_address();
        let mut land = self.lands.read(land_id);
        assert(land.owner == caller, 'Only the current owner can transfer the land');
        assert(land.is_registered, 'Land is not registered');
        land.owner = new_owner;
        land.last_transaction_timestamp = get_block_timestamp();
        self.lands.write(land_id, land);

        // Update owner_lands and owner_land_count
        let from_count = self.owner_land_count.read(caller);
        let to_count = self.owner_land_count.read(new_owner);
        self.owner_lands.write((new_owner, to_count), land_id);
        self.owner_land_count.write(new_owner, to_count + 1);
        self.owner_land_count.write(caller, from_count - 1);

        self.emit(Event::LandTransferred(LandTransferred {
            land_id: land_id,
            from_owner: caller,
            to_owner: new_owner,
        }));

        // Transfer NFT
        ILandNFT::transferFrom(self.land_nft.read(), caller, new_owner, land_id);
    }

    // Implement (get_land_details, get_owner_lands, etc.) 
}

#[starknet::interface]
trait ILandNFT {
    fn mint_land(
        ref self: ContractState,
        to: ContractAddress,
        token_id: u256,
        location: felt252,
        area: u256,
        land_use: felt252,
        document_hash: felt252
    );
    fn transferFrom(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256);
}