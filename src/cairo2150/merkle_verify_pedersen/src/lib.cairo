// Verification of a Pedersen MerkleTree proof created by the npm starknet-merkle-tree library
// Coded with Cairo 2.15.0
// contract not audited ; use at your own risks.

use starknet::ContractAddress;

#[starknet::interface]
pub trait IMerkleVerify<TContractState> {
    fn get_root(self: @TContractState) -> felt252;
    fn get_hash_type(self: @TContractState) -> bytes31;
    fn verify_from_leaf_hash(
        self: @TContractState, leaf_hash: felt252, proof: Span<felt252>,
    ) -> bool;
    fn verify_from_leaf_array(
        self: @TContractState, leaf_array: Span<felt252>, proof: Span<felt252>,
    ) -> bool;
    fn verify_from_leaf_airdrop(
        self: @TContractState, address: ContractAddress, amount: u256, proof: Span<felt252>,
    ) -> bool;
    fn hash_leaf_array(self: @TContractState, leaf: Span<felt252>) -> felt252;
}


#[starknet::contract]
pub mod Merkle {
    use core::hash::{HashStateExTrait, HashStateTrait};
    use core::pedersen::{PedersenTrait, pedersen};
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        pub merkle_root: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, merkle_root: felt252) {
        self.merkle_root.write(merkle_root);
    }


    #[abi(embed_v0)]
    impl MerkleVerifyContract of super::IMerkleVerify<ContractState> {
        fn get_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }

        fn get_hash_type(self: @ContractState) -> bytes31 {
            'PEDERSEN'.try_into().unwrap()
        }

        fn verify_from_leaf_hash(
            self: @ContractState, leaf_hash: felt252, proof: Span<felt252>,
        ) -> bool {
            let hash: felt252 = self._hash_proof(leaf_hash, proof);
            let root: felt252 = self.merkle_root.read();
            hash == root
        }

        fn verify_from_leaf_array(
            self: @ContractState, leaf_array: Span<felt252>, proof: Span<felt252>,
        ) -> bool {
            let leaf_hash = self.hash_leaf_array(leaf_array);
            self.verify_from_leaf_hash(leaf_hash, proof)
        }

        fn verify_from_leaf_airdrop(
            self: @ContractState, address: ContractAddress, amount: u256, proof: Span<felt252>,
        ) -> bool {
            let hash_leaf: felt252 = PedersenTrait::new(0)
                .update_with(address) // .update_with() accepts any type that implements Hash trait
                .update_with(amount.low)
                .update_with(amount.high)
                .update(3) // 3= length of data (address + amount low & high)
                .finalize();
            self.verify_from_leaf_hash(hash_leaf, proof)
        }

        fn hash_leaf_array(self: @ContractState, mut leaf: Span<felt252>) -> felt252 {
            assert(!leaf.is_empty(), 'Empty leaf');
            let mut hash = PedersenTrait::new(0);
            let mut i = 0_u32;
            while i < leaf.len() {
                hash = hash.update(*leaf.at(i));
                i += 1;
            }
            hash.update_with(leaf.len()).finalize()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        // calculate proof hash
        fn _hash_proof(self: @ContractState, leaf: felt252, proofEnter: Span<felt252>) -> felt252 {
            let mut hash = leaf;
            let mut i = 0_u32;
            while i < proofEnter.len() {
                // println!("a,b: 0x{:x} 0x{:x}", hash, *proofEnter[i]);
                let hash_uint256: u256 = hash.into();
                let proof_item: u256 = (*proofEnter[i]).into();
                if hash_uint256 < proof_item {
                    hash = pedersen(hash, *proofEnter[i]);
                    // println!("case 1: 0x{:x}", hash);
                } else {
                    hash = pedersen(*proofEnter[i], hash);
                    // println!("case 2: 0x{:x}", hash);

                }
                i += 1;
            }
            hash
        }
    }
}

#[cfg(test)]
pub mod TestCommon {
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
    use starknet::{ContractAddress, SyscallResultTrait};
    use crate::IMerkleVerifyDispatcher;
    pub fn deploy_test_contract() -> (ContractAddress, IMerkleVerifyDispatcher) {
        let root: felt252 = 0x014623f721f74fcccb0f5377b30b765dcf06da4ff52a7c826a8bf1d5df4ceb87;
        let contract = declare("Merkle").unwrap_syscall().contract_class();
        let (contract_address, _) = contract.deploy(@array![root]).unwrap_syscall();
        let dispatcher = merkle_verify_pedersen::IMerkleVerifyDispatcher { contract_address };
        (contract_address, dispatcher)
    }
}

#[cfg(test)]
mod TestsInternal {
    // use core::result::ResultTrait;
    use merkle_verify_pedersen::Merkle;
    use merkle_verify_pedersen::Merkle::InternalTrait;
    use snforge_std::interact_with_state;
    use starknet::storage::StoragePointerReadAccess;    

    #[test]
    fn test_internal() {
        let (contract_address, _dispatcher) = super::TestCommon::deploy_test_contract();
        interact_with_state(
            contract_address,
            || {
                let mut state = Merkle::contract_state_for_testing();
                let root = state.merkle_root.read();
                // println!("root: 0x{:x}", root);
                let hashed_leaf =
                    0x00b25974bb55dc3155639b41fa8a9ab88a04b2ab0c7f0c044672232566f46931;
                let proof: Span<felt252> = array![
                    0xae3795d0b8e224fd36ad582fab2b5a63622c055be1ffbbdab2ccb90e593ed8,
                    0x371e4224d7f29ea0ac1a1cef66503bd22976a36d5ce3522c138749e72460a4d,
                    0x396b262a230302a113c3db184604546259afc59ddfd2b4824ad1a1438942962,
                    0x8f82aec1bb22a84b365a3cdb9a77589be96df216fd56c0a311bbc2814ca892,
                    0x66d3187101f214a1f9dd9f5d0a6880db9071cd1e9913d4b5fca35615fca6c6b,
                    0x5964794934c488d7fda7ef320b33410734c7c4f1de430bd3693267c0c585a29,
                    0xe2aa42ea209b8a52d6a9d74c1483558e34abc8bad2655cb2133d883c2cbba9,
                    0x23db13b9384b142bad181eb4a852157d14c902545af817c85d7966846b98819,
                    0xc329a0c9c73575abeb78513c0c849820c7590b11d2411fd28a24f736284d1f,
                    0x6b5d33eb4482b16ce60e9f6d3340f67283e5bb542bbc823cdf221deabb9f7be,
                    0x16f0211010fb7cba32b3e49b3c777e7d84f7211828765666f41996ee73fb8b,
                ]
                    .into();
                let proof_hashed = state._hash_proof(hashed_leaf, proof);
                assert(proof_hashed == root, 'error of proof hashing');
            },
        )
    }
}

#[cfg(test)]
mod TestsABI {
    use starknet::ContractAddress;
use merkle_verify_pedersen::IMerkleVerifyDispatcherTrait;
    
    #[test]
    fn test_abi() {
        let (_, dispatcher) = super::TestCommon::deploy_test_contract();
        let root = dispatcher.get_root();

        // 1. get root
        let stored_root = dispatcher.get_root();
        assert(stored_root == root, '1.wrong root stored');

        // 2. hash type
        let hash_type = dispatcher.get_hash_type();
        let tmp: felt252 = hash_type.into();
        // println!("hash_type: 0x{:x}", tmp);
        assert(tmp == 0x504544455253454e, '2.wrong hash');

        // 3. hash leaf
        let leaf: Span<felt252> = array![
            0x21714d78512c4d7cc98f8c3959e9026081f9bb33bbb07066eebc51b6ce357bb, 0x15b, 0x0,
        ]
            .into();
        let hashed_leaf = dispatcher.hash_leaf_array(leaf);
        // println!("hashed_leaf: 0x{:x}", hashed_leaf);
        assert(
            hashed_leaf == 0x00b25974bb55dc3155639b41fa8a9ab88a04b2ab0c7f0c044672232566f46931,
            '3.wrong hash of the leaf',
        );

        // 4.verify_from_leaf_hash
        let proof: Span<felt252> = array![
            0xae3795d0b8e224fd36ad582fab2b5a63622c055be1ffbbdab2ccb90e593ed8,
            0x371e4224d7f29ea0ac1a1cef66503bd22976a36d5ce3522c138749e72460a4d,
            0x396b262a230302a113c3db184604546259afc59ddfd2b4824ad1a1438942962,
            0x8f82aec1bb22a84b365a3cdb9a77589be96df216fd56c0a311bbc2814ca892,
            0x66d3187101f214a1f9dd9f5d0a6880db9071cd1e9913d4b5fca35615fca6c6b,
            0x5964794934c488d7fda7ef320b33410734c7c4f1de430bd3693267c0c585a29,
            0xe2aa42ea209b8a52d6a9d74c1483558e34abc8bad2655cb2133d883c2cbba9,
            0x23db13b9384b142bad181eb4a852157d14c902545af817c85d7966846b98819,
            0xc329a0c9c73575abeb78513c0c849820c7590b11d2411fd28a24f736284d1f,
            0x6b5d33eb4482b16ce60e9f6d3340f67283e5bb542bbc823cdf221deabb9f7be,
            0x16f0211010fb7cba32b3e49b3c777e7d84f7211828765666f41996ee73fb8b,
        ]
            .into();
        let verif_with_leaf_hash = dispatcher.verify_from_leaf_hash(hashed_leaf, proof);
        assert(verif_with_leaf_hash, '4.not verified from leaf hash');

        // 5. verify_from_leaf_array
        let verify_from_leaf_array = dispatcher.verify_from_leaf_array(leaf, proof);
        assert(verify_from_leaf_array, '5.not verified from leaf_array');

        // 6. verify_from_leaf_airdrop
        let addr: ContractAddress = (*leaf[0]).try_into().unwrap();
        let low: u128 = (*leaf[1]).try_into().unwrap();
        let high: u128 = (*leaf[2]).try_into().unwrap();
        let verify_from_leaf_airdrop = dispatcher
            .verify_from_leaf_airdrop(addr, u256 { low: low, high: high }, proof);
        assert(verify_from_leaf_airdrop, '6.not verified from values');
    }
}

