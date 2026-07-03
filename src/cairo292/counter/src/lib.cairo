#[starknet::interface]
trait ICounter<TContractState> {
    //fn test_u384(self:@TContractState)->u384;
    fn increase(ref self: TContractState, x: u128);
    fn getCounter(self: @TContractState) -> u128;
}

#[starknet::contract]
mod test_counter {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;


    #[storage]
    struct Storage {
        counter0: u128,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init: u128) {
        self.counter0.write(init);
    }

    #[abi(embed_v0)]
    impl TestCounter of super::ICounter<ContractState> {
        fn increase(ref self: ContractState, x: u128) {
            self.counter0.write(self.counter0.read() + x)
        }
        fn getCounter(self: @ContractState) -> u128 {
            self.counter0.read()
        }
    }
}
