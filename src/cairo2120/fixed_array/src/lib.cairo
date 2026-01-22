// Coded with Cairo 2.9.2

#[derive(Copy, Drop, Serde)]
struct Point{
    x:u64,
    y:u32
}

#[starknet::interface]
trait ITestFixedArray<TContractState> {
    fn fixed_array(self: @TContractState, x: [u32; 8]) -> [u32; 8];
    fn fixed_array_struct(self: @TContractState, x: [Point; 8]) -> [Point; 8];
    fn fixed_array_array(self: @TContractState, x: [Array<Point>; 8]) -> [Array<Point>; 8];
    fn fixed_array_fixed_array(self: @TContractState, x: [[u32; 8]; 8]) -> [[u32; 8]; 8];
    fn fixed_array_tuple(self: @TContractState, x: [(u32, felt252); 8]) -> [(u32, felt252); 8];
}

#[starknet::contract]
mod testfixed_array {
    use super::Point;

    #[storage]
    struct Storage {
    }

    #[abi(embed_v0)]
    impl TestFixed of super::ITestFixedArray<ContractState> {
        fn fixed_array(self: @ContractState, x: [core::integer::u32; 8]) -> [core::integer::u32; 8] {
            x
        }
        fn fixed_array_struct(self: @ContractState, x: [Point; 8]) -> [Point; 8] {
            x
        }
    fn fixed_array_array(self: @ContractState, x: [Array<Point>; 8]) -> [Array<Point>; 8] {
        x
    }
    fn fixed_array_fixed_array(self: @ContractState, x: [[u32; 8]; 8]) -> [[u32; 8]; 8] {
        x
    }
    fn fixed_array_tuple(self: @ContractState, x: [(u32, felt252); 8]) -> [(u32, felt252); 8] {
        x
    }
    }
}
