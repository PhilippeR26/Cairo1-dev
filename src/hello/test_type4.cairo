#[contract]
mod TestTupple {
    use array::ArrayTrait;
    use option::OptionTrait;


    struct Storage {
        balance: felt252, 
    }

    #[view]
    fn test_tup_out(t: u128, u: felt252, p: u16) -> (u128, u16) {
        let a = (t + 1_u128, p + 1_u16);
        a
    }

    #[view]
    fn test_array_in(mut tab: Array<felt252>) -> (felt252, u32) {
        let a = tab.pop_front().unwrap();
        let b = tab.len();
        (a, b)
    }

    #[view]
    fn test_array_out() -> Array<felt252> {
        let mut a: Array<felt252> = ArrayTrait::new();
        a.append(0_felt252);
        a.append(1_felt252);
        a.append(2_felt252);
        a
    }
 
}
