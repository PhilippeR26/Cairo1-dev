//Cairo 2.6.0

#[starknet::interface]
trait ITestReject<TContractState> {
    fn proceed_bytes31(self: @TContractState, str: bytes31) -> bytes31;
    fn get_string_empty(self: @TContractState) -> ByteArray;
    fn get_string_small(self: @TContractState) -> ByteArray;
    fn get_string(self: @TContractState) -> ByteArray;
    fn proceed_string(self: @TContractState, mess: ByteArray) -> ByteArray;
}

#[starknet::contract]
mod MyTestReject {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::bytes_31::Bytes31Trait;
    use core::byte_array::ByteArrayTrait;
    #[storage]
    struct Storage {
        counter: u8
    }
    
    #[abi(embed_v0)]
    impl TestReject of super::ITestReject<ContractState> {
        fn proceed_bytes31(self: @ContractState, str: bytes31) -> bytes31 {
            let mut mess: ByteArray = "Cairo has become the most popular language for developers!@#$%^&*_+|:'<>?~`";
            mess.append_byte(55_u8);
            str
        }

        fn get_string(self: @ContractState) -> ByteArray {
            let mess: ByteArray = "Cairo has become the most popular language for developers" + " + charizards !@#$%^&*_+|:'<>?~`";
            mess
        }

        fn get_string_empty(self: @ContractState) -> ByteArray {
            let mut mess: ByteArray = "";
            mess
        }

        fn get_string_small(self: @ContractState) -> ByteArray {
            let mut mess: ByteArray = "azertzertrty";
            mess
        }        

        fn proceed_string(self: @ContractState, mess: ByteArray) -> ByteArray {
            let mut res = mess;
            let add: ByteArray = " Zorg is back";
            res.append(@add);
            res
        }
    }
}

