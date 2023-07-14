#[contract]
mod TestConstructor2 {
    use array::ArrayTrait;

    struct Storage {
        text1: felt252, 
    }

    ////////////////////////////////
    // Constructor
    ////////////////////////////////
    #[constructor]
    fn constructor(
        text:felt252,
        mut longText: Array<felt252>,
        mut array1: Array<felt252>
    ) {
        text1::write(*longText.at(0_usize));
    }


    #[view]
    fn test1() -> felt252 {
        text1::read()   
    }

}
