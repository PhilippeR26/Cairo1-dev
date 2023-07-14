#[contract]
mod TestConstructor {
    use starknet::ContractAddress;

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
