use openzeppelin_interfaces::accounts::FeltArrayAccountABIDispatcher;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::{ClassHash, ContractAddress, SyscallResult, SyscallResultTrait};

/// Contract name of the hint variant (60-felt signatures).
pub fn hint_class() -> ByteArray {
    "Falcon512ShakeAccountUpgradeable"
}

/// Contract name of the direct variant (31-felt signatures).
pub fn direct_class() -> ByteArray {
    "Falcon512ShakeDirectAccountUpgradeable"
}

/// Length of a direct signature: packed s1 (29 felts) || salt_a || salt_b.
pub const DIRECT_SIGNATURE_FELTS: u32 = 31;

/// Direct-variant signature: the first 31 felts of a 60-felt hint signature.
pub fn direct(signature: Array<felt252>) -> Array<felt252> {
    let mut values = signature.span();
    let mut output = array![];
    let mut index = 0;
    while index != DIRECT_SIGNATURE_FELTS {
        output.append(*values.pop_front().unwrap());
        index += 1;
    }
    output
}

/// Constructor calldata: the key serialized as `Array<felt252>` (length, then the felts).
fn constructor_calldata(public_key: Array<felt252>) -> Array<felt252> {
    let mut calldata = array![];
    public_key.serialize(ref calldata);
    calldata
}

pub fn class_hash(class_name: ByteArray) -> ClassHash {
    let declared = declare(class_name).unwrap_syscall();
    *declared.contract_class().class_hash
}

/// Deploys without unwrapping, so that constructor failures can be asserted.
pub fn try_deploy(
    class_name: ByteArray, public_key: Array<felt252>,
) -> SyscallResult<(ContractAddress, Span<felt252>)> {
    let declared = declare(class_name).unwrap_syscall();
    declared.contract_class().deploy(@constructor_calldata(public_key))
}

pub fn deploy(class_name: ByteArray, public_key: Array<felt252>) -> FeltArrayAccountABIDispatcher {
    let (contract_address, _) = try_deploy(class_name, public_key).unwrap_syscall();
    FeltArrayAccountABIDispatcher { contract_address }
}

pub fn deploy_at(
    class_name: ByteArray, address: ContractAddress, public_key: Array<felt252>,
) -> FeltArrayAccountABIDispatcher {
    let declared = declare(class_name).unwrap_syscall();
    let (contract_address, _) = declared
        .contract_class()
        .deploy_at(@constructor_calldata(public_key), address)
        .unwrap_syscall();
    FeltArrayAccountABIDispatcher { contract_address }
}
