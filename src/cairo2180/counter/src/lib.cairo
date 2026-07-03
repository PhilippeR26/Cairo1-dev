#[starknet::interface]
trait ICounter<TContractState> {
    //fn test_u384(self:@TContractState)->u384;
    fn increaseCounter(ref self: TContractState, x: u128);
    fn getCounter(self: @TContractState) -> u128;
    fn setCounter(ref self: TContractState, x: u128);
}

#[starknet::contract]
mod test_counter {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};


    #[storage]
    struct Storage {
        counter0: u128,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ChangeCounter: ChangeCounter,
    }

    #[derive(Drop, starknet::Event)]
    struct ChangeCounter {
        #[key]
        value: u128,
    }


    #[constructor]
    fn constructor(ref self: ContractState, init: u128) {
        self.counter0.write(init);
    }

    #[abi(embed_v0)]
    impl TestCounter of super::ICounter<ContractState> {
        fn increaseCounter(ref self: ContractState, x: u128) {
            self.counter0.write(self.counter0.read() + x)
        }
        fn getCounter(self: @ContractState) -> u128 {
            self.counter0.read()
        }
        fn setCounter(ref self: ContractState, x: u128) {
            self.counter0.write(x);
            self.emit(ChangeCounter { value: x })
        }
    }
}
