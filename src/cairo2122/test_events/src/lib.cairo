// Example of events
// Coded with Cairo 2.12.2
// contract not audited ; use at your own risks.

#[starknet::interface]
trait ITestEvent<TContractState> {
    fn send_events(ref self: TContractState, errorType: u8, errorDescription: felt252);
}

#[starknet::contract]
mod send_events {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Claimed: Claimed,
        EventPanic: EventPanic,
    }

    #[derive(Drop, starknet::Event)]
    struct Claimed {
        address: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct EventPanic {
        #[key]
        errorType: u8,
        errorDescription: felt252,
    }

    #[abi(embed_v0)]
    impl TestEvents of super::ITestEvent<ContractState> {
        fn send_events(ref self: ContractState, errorType: u8, errorDescription: felt252) {
            self.emit(EventPanic { errorType, errorDescription });
            return ();
        }
    }
}
