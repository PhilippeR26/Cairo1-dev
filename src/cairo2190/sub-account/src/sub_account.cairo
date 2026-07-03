#[starknet::contract]
pub mod SubAccount {
    use starknet::{ContractAddress, get_caller_address, SyscallResultTrait};
    use starknet::account::Call;
    use starknet::syscalls::call_contract_syscall;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::{ISubAccount, IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        adapters: Map<ContractAddress, bool>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl SubAccountImpl of ISubAccount<ContractState> {
        fn set_adapter(ref self: ContractState, adapter: ContractAddress, allowed: bool) {
            self._assert_owner();
            self.adapters.entry(adapter).write(allowed);
        }

        fn approve_token(
            ref self: ContractState,
            token: ContractAddress,
            spender: ContractAddress,
            amount: u256,
        ) {
            self._assert_owner();
            IERC20Dispatcher { contract_address: token }.approve(spender, amount);
        }

        fn execute(ref self: ContractState, call: Call) -> Span<felt252> {
            self._assert_owner();
            assert(self.adapters.entry(call.to).read(), 'ADAPTER_NOT_ALLOWED');
            // unwrap_syscall (not unwrap) re-panics with the inner revert reason,
            // so a failing adapter/ERC20 call surfaces its real message instead of
            // the opaque 'Result::unwrap failed'.
            call_contract_syscall(call.to, call.selector, call.calldata).unwrap_syscall()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn is_adapter(self: @ContractState, adapter: ContractAddress) -> bool {
            self.adapters.entry(adapter).read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _assert_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'NOT_OWNER');
        }
    }
}
