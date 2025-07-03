// Cairo 2.11.4
// convert an array of short strings to a ByteArray


#[starknet::interface]
pub trait IArrayToByteArray<TContractState> {
    /// Converts an array of felt252 (short strings) into a single ByteArray.
    fn convert_felt252_array_to_bytearray(
        self: @TContractState, felt_array: Array<felt252>,
    ) -> ByteArray;
}

#[starknet::contract]
pub mod ArrayToByteArray {

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl ArrayToByteArrayImpl of super::IArrayToByteArray<ContractState> {
        fn convert_felt252_array_to_bytearray(
            self: @ContractState, felt_array: Array<felt252>,
        ) -> ByteArray {
            let mut byte_array: ByteArray = "";
            let arr_span = felt_array.span();
            let arr_len = arr_span.len();
            let mut pos: u32 = 0;
            while pos != arr_len {
                let short_str: felt252 = *arr_span.at(pos);
                // calculate length of the shortstring
                let mut temp_felt = short_str;
                let mut len: u32 = 0;
                while temp_felt != 0 {
                    if len >= 31 {
                        break;
                    }
                    let temp_u256: u256 = temp_felt
                        .into(); // felt is not handling modulo -> use of u256
                    if temp_u256 % 256 != 0 {
                        len += 1;
                    }
                    temp_felt = (temp_u256 / 256).try_into().unwrap();
                    len += 1;
                }
                byte_array.append_word(short_str, len);
                pos += 1;
            }
            byte_array
        }
    }
}
