// Verification of a Poseidon MerkleTree proof created by the npm starknet-merkle-tree library
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
    use core::poseidon::poseidon_hash_span;
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
            'POSEIDON'.try_into().unwrap()
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
            let low: felt252 = amount.low.into();
            let high: felt252 = amount.high.into();
            let addr: felt252 = address.into();
            let hash_leaf: felt252 = self.hash_leaf_array(array![addr, low, high].into());
            self.verify_from_leaf_hash(hash_leaf, proof)
        }

        fn hash_leaf_array(self: @ContractState, mut leaf: Span<felt252>) -> felt252 {
            assert(!leaf.is_empty(), 'Empty leaf');
            let mut arr = ArrayTrait::<felt252>::new();
            arr.append(0);
            arr.append_span(leaf);
            arr.append(leaf.len().into());
            poseidon_hash_span(arr.span())
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
                    hash = poseidon_hash_span(array![hash, *proofEnter[i]].into());
                    // println!("case 1: 0x{:x}", hash);
                } else {
                    hash = poseidon_hash_span(array![*proofEnter[i], hash].into());
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
        let root: felt252 = 0x2f9e76ae7d7c98e94b848e7bfa684a6158e5f285654d336c9d6524b9ccf7c36;
        let contract = declare("Merkle").unwrap_syscall().contract_class();
        let (contract_address, _) = contract.deploy(@array![root]).unwrap_syscall();
        let dispatcher = merkle_verify_poseidon::IMerkleVerifyDispatcher { contract_address };
        (contract_address, dispatcher)
    }
}

#[cfg(test)]
mod TestsInternal {
    use merkle_verify_poseidon::Merkle;
    use merkle_verify_poseidon::Merkle::InternalTrait;
    use snforge_std:: interact_with_state;
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
                let hashed_leaf = 0x3bc66a9e50bd55b54b8e4adaff861ce8806122c8de4b26808fbabe1204c72a5;
                let proof: Span<felt252> = array![
                    0x3bd82955789dec88b769cb6aa58639609ffdcf7ecde330b4128e8c06ba33e96,
                    0x625b514416c8d9ff4e042d99e2c36451ef4150b3dac7e90c7937205328e49fc,
                    0x1cd267ee25c7e7f9a97aa795185c31d03665f935f7422a36234776fc48040c1,
                    0x339252626ecdc1ad7a99f27077c0f544fadfb1ad818fd4ef9ffc9d7790b1c2f,
                    0x533350ad52c8a0c25cce963a56755d8da5b7f27b01a7e2c0f48a4144ac5c4a9,
                    0x354e60b7a5c80c6f61c807bd641d325dea1ea67578ba61da30c5e42e0987dc9,
                    0x589e68e3645c2455fb11abf65a3e8aa80c8ca66cc6bd52ab5adb34c3c66c53d,
                    0x4424f629835312830bcef6e13e870dee4fceb2afa4feeecdf418be10aadfa74,
                    0x7a305492dec621662e5e63d6f722035632225db604bc8a1b6a66dd6ab1a7e3f,
                    0xc9172a51337520b5762b6c0bc154b0575694b79f4b6605cf26d46562defd9b,
                    0x75105bb3704484d154b4e073654845e8424d71538c0a8827462d6aa6b21d2a5,
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
    use merkle_verify_poseidon::IMerkleVerifyDispatcherTrait;
    use starknet::ContractAddress;

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
        assert(tmp == 0x504f534549444f4e, '2.wrong hash');

        // 3. hash leaf
        let leaf: Span<felt252> = array![
            0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691, 0x3e8, 0x0,
        ]
            .into();
        let hashed_leaf = dispatcher.hash_leaf_array(leaf);
        // println!("hashed_leaf: 0x{:x}", hashed_leaf);
        assert(
            hashed_leaf == 0x3bc66a9e50bd55b54b8e4adaff861ce8806122c8de4b26808fbabe1204c72a5,
            '3.wrong hash of the leaf',
        );

        // 4.verify_from_leaf_hash
        let proof: Span<felt252> = array![
            0x3bd82955789dec88b769cb6aa58639609ffdcf7ecde330b4128e8c06ba33e96,
            0x625b514416c8d9ff4e042d99e2c36451ef4150b3dac7e90c7937205328e49fc,
            0x1cd267ee25c7e7f9a97aa795185c31d03665f935f7422a36234776fc48040c1,
            0x339252626ecdc1ad7a99f27077c0f544fadfb1ad818fd4ef9ffc9d7790b1c2f,
            0x533350ad52c8a0c25cce963a56755d8da5b7f27b01a7e2c0f48a4144ac5c4a9,
            0x354e60b7a5c80c6f61c807bd641d325dea1ea67578ba61da30c5e42e0987dc9,
            0x589e68e3645c2455fb11abf65a3e8aa80c8ca66cc6bd52ab5adb34c3c66c53d,
            0x4424f629835312830bcef6e13e870dee4fceb2afa4feeecdf418be10aadfa74,
            0x7a305492dec621662e5e63d6f722035632225db604bc8a1b6a66dd6ab1a7e3f,
            0xc9172a51337520b5762b6c0bc154b0575694b79f4b6605cf26d46562defd9b,
            0x75105bb3704484d154b4e073654845e8424d71538c0a8827462d6aa6b21d2a5,
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

