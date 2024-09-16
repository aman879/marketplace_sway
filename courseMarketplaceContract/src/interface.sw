library;

abi courseMarketplaceContract {

    #[storage(read, write)]
    fn constructor();

    #[payable]
    #[storage(read, write)]
    fn purchase_course(courseId: b256, proof: b256) -> b256;

    #[payable]
    #[storage(read)]
    fn repurchase_course(courseHash: b256) -> b256;

    #[storage(read)]
    fn activate_course(courseHash: b256) -> b256;

    #[storage(read)]
    fn deactivate_course(courseHash: b256) -> b256;

    #[storage(read)]
    fn withdraw(amount_to_withdraw: u64) -> u64;

    #[storage(read)]
    fn emergency_withdraw() -> u64;

    #[storage(read)]
    fn get_contract_count() -> u64;

    #[storage(read)]
    fn get_course_hash(index: u64) -> b256;
    
    #[storage(read)]
    fn owner() -> Identity;

}