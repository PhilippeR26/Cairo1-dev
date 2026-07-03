#[starknet::contract]
pub mod TimelockTransferAdapter {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use core::poseidon::poseidon_hash_span;
    use crate::interfaces::{
        ITimelockAdapter, PendingRequest, IERC20Dispatcher, IERC20DispatcherTrait,
    };

    #[storage]
    struct Storage {
        owner: ContractAddress,
        delay: u64,
        window: u64,
        // keyed by poseidon(caller, token, recipient, amount) -> one pending request each
        pending: Map<felt252, PendingRequest>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferRequested: TransferRequested,
        TransferExecuted: TransferExecuted,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferRequested {
        #[key]
        caller: ContractAddress,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        executable_at: u64,
        expires_at: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferExecuted {
        #[key]
        caller: ContractAddress,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, delay: u64, window: u64) {
        self.owner.write(owner);
        self.delay.write(delay);
        self.window.write(window);
    }

    #[abi(embed_v0)]
    impl TimelockAdapterImpl of ITimelockAdapter<ContractState> {
        fn request_transfer(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            assert(amount > 0, 'ZERO_AMOUNT');
            let caller = get_caller_address();
            let now = get_block_timestamp();
            let key = key_of(caller, token, recipient, amount);
            let p = self.pending.entry(key).read();

            if p.executable_at == 0 {
                self._arm(key, caller, token, recipient, amount, now);
            } else if now < p.executable_at {
                core::panic_with_felt252('TOO_EARLY');
            } else if now <= p.expires_at {
                // checks-effects-interactions: clear before the external call
                self.pending.entry(key).write(PendingRequest { executable_at: 0, expires_at: 0 });
                IERC20Dispatcher { contract_address: token }
                    .transfer_from(caller, recipient, amount);
                self.emit(TransferExecuted { caller, token, recipient, amount });
            } else {
                // window expired -> re-arm a fresh request
                self._arm(key, caller, token, recipient, amount, now);
            }
        }

        fn set_delay(ref self: ContractState, delay: u64) {
            self._assert_owner();
            self.delay.write(delay);
        }

        fn set_window(ref self: ContractState, window: u64) {
            self._assert_owner();
            self.window.write(window);
        }

        fn pending(
            self: @ContractState,
            caller: ContractAddress,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> PendingRequest {
            self.pending.entry(key_of(caller, token, recipient, amount)).read()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn delay(self: @ContractState) -> u64 {
            self.delay.read()
        }

        fn window(self: @ContractState) -> u64 {
            self.window.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _assert_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'NOT_OWNER');
        }

        // Freeze the bounds using the durations in effect now, so later
        // set_delay/set_window only affect future requests.
        fn _arm(
            ref self: ContractState,
            key: felt252,
            caller: ContractAddress,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            now: u64,
        ) {
            let executable_at = now + self.delay.read();
            let expires_at = executable_at + self.window.read();
            self.pending.entry(key).write(PendingRequest { executable_at, expires_at });
            self
                .emit(
                    TransferRequested {
                        caller, token, recipient, amount, executable_at, expires_at,
                    },
                );
        }
    }

    fn key_of(
        caller: ContractAddress,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    ) -> felt252 {
        poseidon_hash_span(
            array![
                caller.into(), token.into(), recipient.into(), amount.low.into(), amount.high.into(),
            ]
                .span(),
        )
    }
}
