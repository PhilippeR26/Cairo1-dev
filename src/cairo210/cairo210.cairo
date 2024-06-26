//Cairo 2.1.0

#[starknet::interface]
trait ITestC210<TContractState> {
    fn test_felt1(self: @TContractState, p1: felt252, p2: u128, p3: u8) -> u128;
    fn test_len(self: @TContractState, p1: felt252, string_len: felt252,) -> felt252;
}

#[starknet::contract]
mod MyTestFelt {
    #[storage]
    struct Storage {
        counter: u128,
    }

    #[external(v0)]
    impl TestFelt of super::ITestC210<ContractState> {
        fn test_felt1(self: @ContractState, p1: felt252, p2: u128, p3: u8) -> u128 {
            p2 + 1
        }

        fn test_len(self: @ContractState, p1: felt252, string_len: felt252,) -> felt252 {
            string_len
        }
    }
}
