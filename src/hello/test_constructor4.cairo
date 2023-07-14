#[contract]
mod TestConstructor4 {
    use starknet::ContractAddress;
    use array::ArrayTrait;

     #[derive(Copy, Drop, Serde)]
    struct Order {
        p1: felt252,
        p2: felt252,
    }

    impl OrderSerde of serde::Serde::<Order> {
        fn serialize(ref serialized: Array::<felt252>, input: Order) {
            serde::Serde::<felt252>::serialize(ref serialized, input.p1);
            serde::Serde::<felt252>::serialize(ref serialized, input.p2);
        }
        fn deserialize(ref serialized: Span::<felt252>) -> Option::<Order> {
            Option::Some(
                Order {
                    p1: serde::Serde::<felt252>::deserialize(ref serialized)?,
                    p2: serde::Serde::<felt252>::deserialize(ref serialized)?,
                }
            )
        }
    }

    #[derive(Drop, Serde)]
    struct Order2 {
        p1: felt252,
        p2: Array<felt252>,
    }

    impl OrderSerde2 of serde::Serde::<Order2> {
        fn serialize(ref serialized: Array::<felt252>, input: Order2) {
            serde::Serde::<felt252>::serialize(ref serialized, input.p1);
            serde::Serde::<Array<felt252>>::serialize(ref serialized, input.p2);
        }
        fn deserialize(ref serialized: Span::<felt252>) -> Option::<Order2> {
            Option::Some(
                Order2 {
                    p1: serde::Serde::<felt252>::deserialize(ref serialized)?,
                    p2: serde::Serde::<Array<felt252>>::deserialize(ref serialized)?,
                }
            )
        }
    }

// #[derive(Drop, Serde)]
//     struct Order3 {
//         p11: Order,
//         p12: Order2,
//     }


    struct Storage {
        balance: felt252, 
    }

    ////////////////////////////////
    // Constructor
    ////////////////////////////////
    #[constructor]
    fn constructor(
        name: felt252,
        symbol: felt252,
        decimals: u8,
        initial_supply: u256,
        card: Order2,
        recipient: ContractAddress,
        active:bool,
        coord:(felt252,u16),
        mut longText: Array<felt252>,
        mut array1:Array<u128>,
        mut array2:Array<Array<u16>>,
        mut array3:Array<Order2>,
        mut array4:Array<u256>,
        tuple1:(u8,u16,u32,u64),
        mut array5:Array<(u8,u16)>,
    ) {
        
    }


    #[view]
    fn test1(p1: felt252) -> felt252 {
        p1 + 1_felt252
    }

}
