#[contract]
mod HelloStarknet {
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    struct Storage {
        balance: felt252, 
    }

    #[derive(Serde)]
    struct Storage1 {
        balance: felt252,
        amount: u128
    }
    #[derive(Serde)]
    struct Storage2 {
        balance: u256,
        status: bool
    }

    #[view]
    fn test_u256(p1: u256) -> u256 {
        let to_add = u256 { low: 1_u128, high: 0_u128 };
        p1 + to_add
    }

    #[view]
    fn test_felt252(p1: felt252) -> felt252 {
        p1 + 1_felt252
    }

    #[view]
    fn test_u128(p1: u128) -> u128 {
        let a: u128 = 4_u128;
        p1 + 2_u128
    }

    #[view]
    fn test_u64(p1: u64) -> u64 {
        let a: u64 = 4_u64;
        p1 + 3_u64
    }

    #[view]
    fn test_u32(p1: u32) -> u32 {
        let a: u32 = 4_u32;
        p1 + 4_u32
    }

    #[view]
    fn test_usize(p1: usize) -> usize {
        let a: usize = 4_usize;
        p1 + 5_usize
    }

    #[view]
    fn test_u16(p1: u16) -> u16 {
        let a: u16 = 4_u16;
        p1 + 6_u16
    }

    #[view]
    fn test_u8(p1: u8) -> u8 {
        let a: u8 = 4_u8;
        p1 + 7_u8
    }

    #[view]
    fn test_bool() -> bool {
        let a: bool = true;
        a
    }

    #[view]
    fn test_address() -> bool {
        let a: bool = true;
        a
    }

    #[view]
    fn test_struct1(enter: Storage1) -> Storage1 {
        let a = Storage1 { balance: enter.balance + 1_felt252, amount: enter.amount + 1_u128 };
        a
    }

    #[view]
    fn test_struct2(enter: Storage2) -> Storage2 {
        let to_add = u256 { low: 1_u128, high: 0_u128 };

        let a = Storage2 { balance: enter.balance + to_add, status: true };
        a
    }

    // Increases the balance by the given amount.
    #[external]
    fn increase_balance(amount: felt252) {
        balance::write(balance::read() + amount);
    }

    // Returns the current balance.
    #[view]
    fn get_balance() -> felt252 {
        balance::read()
    }
}
