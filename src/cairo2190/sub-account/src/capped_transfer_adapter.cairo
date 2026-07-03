#[starknet::contract]
pub mod CappedTransferAdapter {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use crate::interfaces::{IAdapter, IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        token: ContractAddress,
        recipient: ContractAddress,
        cap: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        cap: u256,
    ) {
        self.token.write(token);
        self.recipient.write(recipient);
        self.cap.write(cap);
    }

    #[abi(embed_v0)]
    impl AdapterImpl of IAdapter<ContractState> {
        fn pull_and_transfer(ref self: ContractState, amount: u256) {
            assert(amount <= self.cap.read(), 'CAP_EXCEEDED');
            let caller = get_caller_address();
            IERC20Dispatcher { contract_address: self.token.read() }
                .transfer_from(caller, self.recipient.read(), amount);
        }

        fn token(self: @ContractState) -> ContractAddress {
            self.token.read()
        }

        fn recipient(self: @ContractState) -> ContractAddress {
            self.recipient.read()
        }

        fn cap(self: @ContractState) -> u256 {
            self.cap.read()
        }
    }
}
