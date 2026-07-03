use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, amount: u256);
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256,
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(
        self: @TContractState, owner: ContractAddress, spender: ContractAddress,
    ) -> u256;
}

#[starknet::interface]
pub trait IAdapter<TContractState> {
    fn pull_and_transfer(ref self: TContractState, amount: u256);
    fn token(self: @TContractState) -> ContractAddress;
    fn recipient(self: @TContractState) -> ContractAddress;
    fn cap(self: @TContractState) -> u256;
}

use starknet::account::Call;

#[starknet::interface]
pub trait ISubAccount<TContractState> {
    fn set_adapter(ref self: TContractState, adapter: ContractAddress, allowed: bool);
    fn approve_token(
        ref self: TContractState,
        token: ContractAddress,
        spender: ContractAddress,
        amount: u256,
    );
    fn execute(ref self: TContractState, call: Call) -> Span<felt252>;
    fn owner(self: @TContractState) -> ContractAddress;
    fn is_adapter(self: @TContractState, adapter: ContractAddress) -> bool;
}

// A timelocked transfer request, keyed off (caller, token, recipient, amount).
// Bounds are frozen at request time, so changing delay/window only affects future requests.
#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct PendingRequest {
    pub executable_at: u64,
    pub expires_at: u64,
}

#[starknet::interface]
pub trait ITimelockAdapter<TContractState> {
    fn request_transfer(
        ref self: TContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    );
    fn set_delay(ref self: TContractState, delay: u64);
    fn set_window(ref self: TContractState, window: u64);
    fn pending(
        self: @TContractState,
        caller: ContractAddress,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    ) -> PendingRequest;
    fn owner(self: @TContractState) -> ContractAddress;
    fn delay(self: @TContractState) -> u64;
    fn window(self: @TContractState) -> u64;
}
