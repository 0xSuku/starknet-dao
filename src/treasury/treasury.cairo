#[contract]
mod Treasury {
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::contract_address_try_from_felt252;
    use starknet::ContractAddress;

    struct Storage {
        balance: u256,
        owner: ContractAddress,
        has_owner: u8
    }

    #[constructor]
    fn constructor() {
        let owner = get_caller_address();
        owner::write(owner);
        has_owner::write(0);
        balance::write(0);

        ()
    }

    #[view]
    fn get_balance() -> u256 {
        balance::read()
    }

    #[view]
    fn get_owner() -> ContractAddress {
        owner::read()
    }

    #[external]
    fn deposit(amount: u256) {
        let current_owner = owner::read();
        let caller = get_caller_address();
        let this_contract = get_contract_address();        
        let eth_contract: ContractAddress = contract_address_try_from_felt252(0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7).unwrap();
        assert(current_owner == caller, 'CALLER_NOT_OWNER');

        let current_balance = balance::read();
        assert(amount >= 0_u256, 'DEPOSIT_MUST_BE_POSITIVE');

        balance::write(current_balance + amount);
        IERC20Dispatcher {contract_address: eth_contract}.transfer_from(caller, this_contract, amount)
    }

    #[external]
    fn withdraw(amount: u256) {
        let current_owner = owner::read();
        let caller = get_caller_address();
        assert(current_owner == caller, 'CALLER_NOT_OWNER');

        let current_balance = balance::read();
        assert(amount >= 0_u256, 'WITHDRAWAL_MUST_BE_POSITIVE');
        assert(current_balance >= amount, 'INSUFFICIENT_FUNDS');
        
        balance::write(current_balance - amount);
    }

    #[external]
    fn set_owner(new_owner: ContractAddress) {
        if (has_owner::read() == 0) {
            owner::write(new_owner);
            has_owner::write(1);
        } else {
            let caller = get_caller_address();
            let current_owner = owner::read();
            assert(current_owner == caller, 'CALLER_NOT_OWNER');
            
            owner::write(new_owner);
            return ();
        }
        assert(1 == 1, 'NOT_PERMITTED');
    }

    #[external]
    fn renounce_ownership(new_owner: ContractAddress) {
        if (has_owner::read() != 0) {
            let caller = get_caller_address();
            let current_owner = owner::read();
            assert(current_owner == caller, 'CALLER_NOT_OWNER');
            
            owner::write(caller);
            has_owner::write(0);
            return ();
        }
        assert(1 == 1, 'NOT_OWNED');
    }
}