use starknet::ContractAddress;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use sub_account::interfaces::{IERC20Dispatcher, IERC20DispatcherTrait};

fn deploy_erc20() -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![]).unwrap();
    addr
}

#[test]
fn test_mint_and_transfer_from() {
    let holder: ContractAddress = 'holder'.try_into().unwrap();
    let spender: ContractAddress = 'spender'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let token = deploy_erc20();
    let erc = IERC20Dispatcher { contract_address: token };

    erc.mint(holder, 1000);

    // holder approves spender for 500
    start_cheat_caller_address(token, holder);
    erc.approve(spender, 500);
    stop_cheat_caller_address(token);

    // spender pulls 200 from holder to recipient
    start_cheat_caller_address(token, spender);
    erc.transfer_from(holder, recipient, 200);
    stop_cheat_caller_address(token);

    assert(erc.balance_of(holder) == 800, 'BAD_HOLDER_BAL');
    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
    assert(erc.allowance(holder, spender) == 300, 'BAD_ALLOWANCE');
}

#[test]
#[should_panic(expected: 'INSUFFICIENT_ALLOWANCE')]
fn test_transfer_from_without_allowance() {
    let holder: ContractAddress = 'holder'.try_into().unwrap();
    let spender: ContractAddress = 'spender'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    let token = deploy_erc20();
    let erc = IERC20Dispatcher { contract_address: token };
    erc.mint(holder, 1000);

    start_cheat_caller_address(token, spender);
    erc.transfer_from(holder, recipient, 200);
    stop_cheat_caller_address(token);
}
