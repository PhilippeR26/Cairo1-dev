#[contract]
mod HelloStarknet {
    use array::ArrayTrait;

    //simple struct
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

    #[view]
    fn create_order_template() -> Order {
        Order { 
            p1: 12, 
            p2: 23, 
             }
    }
    // complex struct1

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
    #[view]
    fn create_order_complex() -> Order2 {
        let mut a: Array<felt252> = ArrayTrait::new();
        a.append(17_felt252);
        a.append(18_felt252);
        a.append(19_felt252);

        let obj=Order2 { p1: 12, p2: a,  };
        obj
    }
}
