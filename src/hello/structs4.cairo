#[contract]
mod struct4 {
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
        Order { p1: 12, p2: 23,  }
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

    #[view]
    fn get_order() -> Order {
        Order { p1: 34_felt252, p2: 45_felt252 }
    }

    #[view]
    fn get_order2() -> Order2 {
        let mut a: Array<felt252> = ArrayTrait::new();
        a.append(17_felt252);
        a.append(18_felt252);
        a.append(19_felt252);
        Order2 { p1: 34_felt252, p2: a }
    }

    #[view]
    fn get_order3(obj: Order) -> felt252 {
        obj.p1
    }

    #[view]
    fn get_order4(obj: Order2) -> felt252 {
        obj.p1
    }


    #[view]
    fn render_tuple() -> (u8, u256, u128) {
        let b = u256 { low: 1_u128, high: 17_u128 };
        (1_u8, b, 3456_u128)
    }
}
