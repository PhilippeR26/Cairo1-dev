#[contract]
mod HelloStarknet {
    use starknet::ContractAddress;
    use starknet::contract_address_const;

    struct Storage {
        balance: felt252, 
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
        p1 + 7_u8
    }

    #[view]
    fn test_bool(b:bool) -> bool {
        let a: bool = true;
        a
    }

    #[view]
    fn test_address(to_addr:ContractAddress) -> ContractAddress {
        let a: ContractAddress = contract_address_const::<0x771bbe2ba64fa5ab52f0c142b4296fc67460a3a2372b4cdce752c620e3e8194>();
        a
    }

   #[view]
    fn test_multi1(p1: u8,p2:u256,p3:u128) -> u8 {
        p1 + 7_u8
    }

   #[view]
    fn test_multi2(p1: u8,p2:u64,p3:u128) -> u8 {
        p1 + 7_u8
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
