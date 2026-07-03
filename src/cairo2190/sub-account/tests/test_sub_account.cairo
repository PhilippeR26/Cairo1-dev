use starknet::ContractAddress;
use starknet::account::Call;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use sub_account::interfaces::{
    IERC20Dispatcher, IERC20DispatcherTrait, ISubAccountDispatcher, ISubAccountDispatcherTrait,
};

fn deploy_erc20() -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![]).unwrap();
    addr
}

fn deploy_subaccount(owner: ContractAddress) -> ContractAddress {
    let contract = declare("SubAccount").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![owner.into()]).unwrap();
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

// full scenario: owner registers adapter, grants allowance, executes a capped transfer
fn setup() -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let sub = deploy_subaccount(owner);
    let adapter = deploy_adapter(token, recipient, 500);
    IERC20Dispatcher { contract_address: token }.mint(sub, 1000);
    (owner, recipient, token, sub, adapter)
}

fn pull_call(adapter: ContractAddress, amount: u256) -> Call {
    let mut cd = array![];
    amount.serialize(ref cd);
    Call { to: adapter, selector: selector!("pull_and_transfer"), calldata: cd.span() }
}

#[test]
fn test_execute_happy_path() {
    let (owner, recipient, token, sub, adapter) = setup();
    let sub_disp = ISubAccountDispatcher { contract_address: sub };

    start_cheat_caller_address(sub, owner);
    sub_disp.set_adapter(adapter, true);
    sub_disp.approve_token(token, adapter, 500);
    sub_disp.execute(pull_call(adapter, 200));
    stop_cheat_caller_address(sub);

    let erc = IERC20Dispatcher { contract_address: token };
    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
    assert(erc.balance_of(sub) == 800, 'BAD_SUB_BAL');
    assert(sub_disp.is_adapter(adapter), 'ADAPTER_NOT_REGISTERED');
}

#[test]
#[should_panic(expected: 'NOT_OWNER')]
fn test_execute_non_owner() {
    let (_owner, _recipient, token, sub, adapter) = setup();
    let sub_disp = ISubAccountDispatcher { contract_address: sub };
    // register + approve as owner first
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    start_cheat_caller_address(sub, owner);
    sub_disp.set_adapter(adapter, true);
    sub_disp.approve_token(token, adapter, 500);
    stop_cheat_caller_address(sub);
    // now call execute as a stranger (no cheat -> caller is the test address)
    sub_disp.execute(pull_call(adapter, 200));
}

#[test]
#[should_panic(expected: 'ADAPTER_NOT_ALLOWED')]
fn test_execute_non_whitelisted() {
    let (owner, _recipient, _token, sub, adapter) = setup();
    let sub_disp = ISubAccountDispatcher { contract_address: sub };
    // owner calls execute but never whitelisted the adapter
    start_cheat_caller_address(sub, owner);
    sub_disp.execute(pull_call(adapter, 200));
    stop_cheat_caller_address(sub);
}

#[test]
#[should_panic(expected: 'ADAPTER_NOT_ALLOWED')]
fn test_execute_adapter_removed() {
    let (owner, _recipient, token, sub, adapter) = setup();
    let sub_disp = ISubAccountDispatcher { contract_address: sub };
    start_cheat_caller_address(sub, owner);
    sub_disp.set_adapter(adapter, true);
    sub_disp.approve_token(token, adapter, 500);
    sub_disp.set_adapter(adapter, false); // remove from whitelist
    sub_disp.execute(pull_call(adapter, 200));
    stop_cheat_caller_address(sub);
}

#[test]
#[should_panic(expected: 'NOT_OWNER')]
fn test_set_adapter_non_owner() {
    let (_owner, _recipient, _token, sub, adapter) = setup();
    // no cheat -> caller != owner
    ISubAccountDispatcher { contract_address: sub }.set_adapter(adapter, true);
}
