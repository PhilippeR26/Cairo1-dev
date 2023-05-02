#[contract]
mod HelloStarknet {
    
    #[view]
    fn create_order_template() -> Order {
        Order {
            p1: 12,
            p2: 23,
        }
    }
}
