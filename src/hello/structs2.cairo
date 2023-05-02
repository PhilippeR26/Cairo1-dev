#[contract]
mod HelloStarknet {
    #[derive(Copy, Drop,Serde)]
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

    
}
