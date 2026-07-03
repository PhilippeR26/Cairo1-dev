// Test.
// Coded with Cairo 2.18.0
// contract not audited ; use at your own risks.

#[starknet::interface]
pub trait ITest2180<TContractState> {
    fn calc1(ref self: TContractState, data: u128);
    fn get_value(self: @TContractState) -> u128;
}

#[starknet::contract]
mod Test2180 {
    use core::array::ArrayTrait;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    // ──────────────────────────────────────────────
    // Storage
    // ──────────────────────────────────────────────
    #[storage]
    pub struct Storage {
        pub result: u128,
    }

    // ──────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // ──────────────────────────────────────────────
    // Constructor
    // ──────────────────────────────────────────────
    #[constructor]
    fn constructor(ref self: ContractState) {}

    // ──────────────────────────────────────────────
    // Internal functions
    // ──────────────────────────────────────────────
    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn _calc(self: @ContractState, input: u128) -> u128 {
            input + 1
        }
    }

    // ──────────────────────────────────────────────
    // external abi functions
    // ──────────────────────────────────────────────
    #[abi(embed_v0)]
    impl TestContract of super::ITest2180<ContractState> {
        fn calc1(ref self: ContractState, data: u128) {
            let res = self._calc(data);
            self.result.write(res);
        }
        fn get_value(self: @ContractState) -> u128 {
            self.result.read()
        }
    }
}

#[cfg(test)]
pub mod TestCommon {
    use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
    use starknet::{ContractAddress, SyscallResultTrait};
    use crate::ITest2180Dispatcher;
    pub fn deploy_test_contract() -> (ContractAddress, ITest2180Dispatcher) {
        // let root: felt252 = 0x014623f721f74fcccb0f5377b30b765dcf06da4ff52a7c826a8bf1d5df4ceb87;
        let contract = declare("Test2180").unwrap_syscall().contract_class();
        let (contract_address, _) = contract.deploy(@array![]).unwrap_syscall();
        let dispatcher = test_2180::ITest2180Dispatcher { contract_address };
        (contract_address, dispatcher)
    }
}

#[cfg(test)]
mod TestsInternal {
    use snforge_std::interact_with_state;
    use starknet::storage::StoragePointerReadAccess;
    use crate::Test2180;
    use crate::Test2180::InternalTrait;

    #[test]
    fn test_internal() {
        let (contract_address, _dispatcher) = super::TestCommon::deploy_test_contract();
        interact_with_state(
            contract_address,
            || {
                let mut state = Test2180::contract_state_for_testing();
                let res_calc = state._calc(10);
                assert(res_calc == 11, 'error of proof hashing');
                let value = state.result.read();
                assert(value == 0, 'error2');
            },
        )
    }
}

#[cfg(test)]
mod TestsExternal {
    use crate::ITest2180DispatcherTrait;

    #[test]
    fn test_internal() {
        let (_, dispatcher) = super::TestCommon::deploy_test_contract();
        dispatcher.calc1(20);
        let root = dispatcher.get_value();
        assert(root == 21, 'wrong calc');
    }
}

