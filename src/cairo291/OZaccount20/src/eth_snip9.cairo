// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.17.0

// Account 0.17.0 Eth Upgradable outsideExecution
#[starknet::contract(account)]
pub mod AccountEthSnip9OZ20 {
    use openzeppelin::account::extensions::SRC9Component::InternalTrait;
    use openzeppelin::account::eth_account::EthAccountComponent;
    use openzeppelin::account::interface::EthPublicKey;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::ClassHash;
    use openzeppelin::account::extensions::SRC9Component;

    component!(path: EthAccountComponent, storage: eth_account, event: EthAccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: SRC9Component, storage: src9, event: SRC9Event);

    #[abi(embed_v0)]
    impl EthAccountMixinImpl =
        EthAccountComponent::EthAccountMixinImpl<ContractState>;

    impl EthAccountInternalImpl = EthAccountComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        eth_account: EthAccountComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        src9: SRC9Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        EthAccountEvent: EthAccountComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        SRC9Event: SRC9Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: EthPublicKey) {
        self.eth_account.initializer(public_key);
        self.src9.initializer();
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.eth_account.assert_only_self();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
    #[abi(embed_v0)]
    impl src9Imp = SRC9Component::OutsideExecutionV2Impl<ContractState>;
}
