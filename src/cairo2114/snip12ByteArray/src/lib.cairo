// Cairo 2.11.4

pub mod snip12;
pub mod utils;
use snip12::struct_long_string::LongString;
use starknet::ContractAddress;

#[starknet::interface]
trait ITestByteArray<TContractState> {
    fn get_hash_domain(self: @TContractState, name: felt252) -> felt252;
    fn get_hash_message(
        self: @TContractState, message: LongString, account_addr: ContractAddress
    ) -> felt252;
    fn get_hash_struct_message(self: @TContractState, struct_array: LongString) -> felt252;
    fn reset_storage(ref self: TContractState);
    fn get_storage(self: @TContractState) -> ByteArray;
    fn process_message(ref self: TContractState, message: LongString, signature: Array<felt252>);
    fn to_byte_array(self: @TContractState, inp: LongString) -> ByteArray;
}

#[starknet::contract]
mod test_bytearray {
    use super::snip12::structure::IStructHash;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::snip12::struct_long_string::LongString;
    use super::snip12::message::OffchainMessageHashLongString;
    use super::snip12::sn_domain::StarknetDomain;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, syscalls, SyscallResultTrait, get_tx_info};
    use super::utils::shortstring2bytearray::convert_felt252_array_to_bytearray;

    #[storage]
    struct Storage {
        irl: ByteArray,
    }

    #[abi(embed_v0)]
    impl TestByteArray of super::ITestByteArray<ContractState> {
        fn get_hash_domain(self: @ContractState, name: felt252) -> felt252 {
            let my_domain = StarknetDomain {
                name: name, chain_id: get_tx_info().unbox().chain_id, version: 1
            };
            // name: name, version: 1, chain_id: chain };
            my_domain.hash_struct()
        }

        fn get_hash_message(
            self: @ContractState, message: LongString, account_addr: ContractAddress
        ) -> felt252 {
            message.get_message_hash(account_addr)
        }

        fn get_hash_struct_message(self: @ContractState, struct_array: LongString) -> felt252 {
            struct_array.hash_struct()
        }

        fn reset_storage(ref self: ContractState) {
            self.irl.write("");
        }

        fn get_storage(self: @ContractState) -> ByteArray {
            self.irl.read()
        }

        fn process_message(
            ref self: ContractState, message: LongString, signature: Array<felt252>
        ) {
            let arr = message.to_store.clone();
            let mess2 = LongString { to_store: arr };
            let msg_hash = self.get_hash_message(mess2, get_caller_address());
            let mut call_data: Array<felt252> = array![];
            Serde::serialize(@msg_hash, ref call_data);
            Serde::serialize(@signature, ref call_data);

            let mut res = syscalls::call_contract_syscall(
                get_caller_address(), selector!("is_valid_signature"), call_data.span()
            )
                .unwrap_syscall();

            let result = Serde::<felt252>::deserialize(ref res).unwrap();
            if result == starknet::VALIDATED {
                let text: ByteArray = self.to_byte_array(message);
                self.irl.write(text);
            } else {
                self.irl.write("Fail");
            }
        }

        fn to_byte_array(self: @ContractState,inp: LongString) -> ByteArray {
            let inp2: Array<felt252> = inp.to_store;
           convert_felt252_array_to_bytearray(inp2)
        }
    }
}
