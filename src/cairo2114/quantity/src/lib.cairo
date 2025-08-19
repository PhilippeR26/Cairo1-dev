// Coded with Cairo 2.11.4
#[starknet::interface]
trait INameStarknet<TContractState> {
    fn increase_qty_weapons(ref self: TContractState, qty: u16);
    fn decrease_qty_weapons(ref self: TContractState, qty: u16);
    fn set_qty_weapons(ref self: TContractState, qty: u16);
    fn get_qty_weapons(self: @TContractState) -> u16;
}


#[starknet::contract]
mod NameStarknet {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;

    #[storage]
    struct Storage {
        qty_weapons: u16,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::INameStarknet<ContractState> {
        fn increase_qty_weapons(ref self: ContractState, qty: u16) {
            self.qty_weapons.write(self.qty_weapons.read()+qty);
        }

        fn decrease_qty_weapons(ref self: ContractState, qty: u16) {
            self.qty_weapons.write(self.qty_weapons.read()-qty);
        }

        fn set_qty_weapons(ref self: ContractState, qty: u16) {
            self.qty_weapons.write(qty);
        }

        fn get_qty_weapons(self: @ContractState) -> u16 {
            self.qty_weapons.read()
        }
    }
}