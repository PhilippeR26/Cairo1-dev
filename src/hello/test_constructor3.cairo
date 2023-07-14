#[contract]
mod TestConstructor3 {
    use starknet::ContractAddress;
    use array::ArrayTrait;

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
    ) {
        
    }


    #[view]
    fn test1(p1: felt252) -> felt252 {
        p1 + 1_felt252
    }

}
