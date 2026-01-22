#[starknet::interface]
trait IHelloContract<TContractState> {
    fn Say_HelloPhil126(ref self: TContractState, messages: felt252);
}
#[starknet::contract]
mod HelloStarknet {
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Hello: Hello, 
    }

    #[derive(Drop, starknet::Event)]
    struct Hello {
        #[key]
        from: ContractAddress,
        value: felt252
    }

    #[abi(embed_v0)]
    impl HelloContract of super::IHelloContract<ContractState> {
        fn Say_HelloPhil126(ref self: ContractState, messages: felt252) {
            let caller = get_caller_address();
            self.emit(Hello { from: caller, value: messages }); // event
        }
    }
}
