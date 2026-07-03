use starknet::ContractAddress;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use sub_account::interfaces::{
    IERC20Dispatcher, IERC20DispatcherTrait, IAdapterDispatcher, IAdapterDispatcherTrait,
};

fn deploy_erc20() -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![]).unwrap();
    addr
}

fn deploy_adapter(token: ContractAddress, recipient: ContractAddress, cap: u256) -> ContractAddress {
    let contract = declare("CappedTransferAdapter").unwrap().contract_class();
    let mut cd = array![];
    token.serialize(ref cd);
    recipient.serialize(ref cd);
    cap.serialize(ref cd);
    let (addr, _) = contract.deploy(@cd).unwrap();
    addr
}

#[test]
fn test_pull_and_transfer_happy() {
    let holder: ContractAddress = 'holder'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let token = deploy_erc20();
    let adapter = deploy_adapter(token, recipient, 500);
    let erc = IERC20Dispatcher { contract_address: token };

    erc.mint(holder, 1000);

    // holder authorizes the adapter to pull up to 500
    start_cheat_caller_address(token, holder);
    erc.approve(adapter, 500);
    stop_cheat_caller_address(token);

    // holder calls the adapter -> adapter pulls holder's funds to recipient
    start_cheat_caller_address(adapter, holder);
    IAdapterDispatcher { contract_address: adapter }.pull_and_transfer(200);
    stop_cheat_caller_address(adapter);

    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
    assert(erc.balance_of(holder) == 800, 'BAD_HOLDER_BAL');
}

#[test]
#[should_panic(expected: 'CAP_EXCEEDED')]
fn test_pull_and_transfer_cap_exceeded() {
    let holder: ContractAddress = 'holder'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let token = deploy_erc20();
    let adapter = deploy_adapter(token, recipient, 500);
    IERC20Dispatcher { contract_address: token }.mint(holder, 1000);

    start_cheat_caller_address(adapter, holder);
    IAdapterDispatcher { contract_address: adapter }.pull_and_transfer(600);
    stop_cheat_caller_address(adapter);
}
