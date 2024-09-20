// Coded with Cairo 2.7.0
#[starknet::interface]
trait ITestL1L2<TContractState> {
    fn get_balance(self: @TContractState) -> u128;
    fn get_lock_status(self: @TContractState) -> bool;
    fn lock(ref self: TContractState, to_lock: bool);
}

#[starknet::contract]
mod checkMessageGift {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        is_locked: bool,
        balance: u128,
    }

    #[l1_handler]
    fn execute_l1(ref self: ContractState, from_address: felt252, balance: u128) {
        assert!(!self.is_locked.read(), "Not authorized balance.");
        self.balance.write(balance);
    }

    #[abi(embed_v0)]
    impl testL1L2 of super::ITestL1L2<ContractState> {
        fn get_balance(self: @ContractState) -> u128 {
            self.balance.read()
        }

        fn get_lock_status(self: @ContractState) -> bool {
            self.is_locked.read()
        }

        fn lock(ref self: ContractState, to_lock: bool) {
            self.is_locked.write(to_lock);
        }
    }
}
