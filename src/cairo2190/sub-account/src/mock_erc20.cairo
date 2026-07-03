#[starknet::contract]
pub mod MockERC20 {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::IERC20;

    #[storage]
    struct Storage {
        balances: Map<ContractAddress, u256>,
        allowances: Map<(ContractAddress, ContractAddress), u256>,
    }

    #[abi(embed_v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.balances.entry(to).write(self.balances.entry(to).read() + amount);
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) {
            self._transfer(get_caller_address(), to, amount);
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256,
        ) {
            let spender = get_caller_address();
            let current = self.allowances.entry((from, spender)).read();
            assert(current >= amount, 'INSUFFICIENT_ALLOWANCE');
            self.allowances.entry((from, spender)).write(current - amount);
            self._transfer(from, to, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            self.allowances.entry((get_caller_address(), spender)).write(amount);
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.entry(account).read()
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress,
        ) -> u256 {
            self.allowances.entry((owner, spender)).read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256,
        ) {
            let bal = self.balances.entry(from).read();
            assert(bal >= amount, 'INSUFFICIENT_BALANCE');
            self.balances.entry(from).write(bal - amount);
            self.balances.entry(to).write(self.balances.entry(to).read() + amount);
        }
    }
}
