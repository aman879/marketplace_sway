contract;

mod data_structure;
mod errors;
mod interface;

use ::data_structure::{course::Course, state::CourseState};
use ::errors::CourseMarketplaceError;
use ::interface::courseMarketplaceContract;

use std::{
    asset::transfer,
    context::this_balance,
    call_frames::msg_asset_id,
    context::msg_amount,
    auth::msg_sender,
    hash::{keccak256, Hash},
    constants::ZERO_B256,
    address::Address,
};

use sway_libs::pausable::{
    _is_paused,
    _pause,
    _unpause,
    Pausable,
    require_not_paused,
};

storage {
    ownedCourses: StorageMap<b256, Course> = StorageMap {},
    ownedCourseHash: StorageMap<u64, b256> = StorageMap {},
    totalOwnedCourses: u64 = 0,
    owner: Identity = Identity::Address(Address::zero()),
}

impl Pausable for Contract {
    #[storage(write)]
    fn pause() {
        only_owner();
        _pause();
    }

    #[storage(read)]
    fn is_paused() -> bool {
        _is_paused()
    }

    #[storage(write)]
    fn unpause() {
        only_owner();
        _unpause();
    }
}


#[storage(read)]
fn is_course_created(courseHash: b256) -> bool {
    match storage.ownedCourses.get(courseHash).try_read() {
        Some(_) => true, 
        None => false, 
    }
}

#[storage(read)]
fn has_course_ownership(courseHash: b256) -> bool {

    let sender = msg_sender().unwrap();

    let course = storage.ownedCourses.get(courseHash).try_read();
    let mut course = course.unwrap();
    let ownerB256 = course.owner;
    let owner:Identity = Identity::Address(Address::from(ownerB256));

    if sender == owner {
        true
    } else {
        false
    }
}

fn decompose(value: b256) -> (u64, u64, u64, u64) {
    asm(r1: __addr_of(value)) {
        r1: (u64, u64, u64, u64)
    }
}

fn encode_two_variables(courseId: b256) -> Vec<u64> {
    let mut data = Vec::with_capacity(9);
    // Encode each variable separately
    let sender = msg_sender().unwrap();
    let mut sender: b256 = match sender {
        Identity::Address(address) => address.into(),
        Identity::ContractId(contract_id) => contract_id.into(),
    };
    
    let (course_1, course_2, course_3, course_4) = decompose(courseId);
    let (sender_1, sender_2, sender_3, sender_4) = decompose(sender);
    
    data.push(course_1 >> 16);
    data.push((course_1 << 48) + (course_2 >> 16));
    data.push((course_2 << 48) + (course_3 >> 16));
    data.push((course_3 << 48) + (course_4 >> 16));
    data.push((course_4 << 48) + (sender_1 >> 16));
    data.push((sender_1 << 48) + (sender_2 >> 16));
    data.push((sender_2 << 48) + (sender_3 >> 16));
    data.push((sender_3 << 48) + (sender_4 >> 16));
    data.push(sender_4 << 48);
    
    data
}

fn get_keccak(courseId:b256) -> b256 {
    let encoded_data = encode_two_variables(courseId);
    let encoded_data = (
        encoded_data.get(0).unwrap(),
        encoded_data.get(1).unwrap(),
        encoded_data.get(2).unwrap(),
        encoded_data.get(3).unwrap(),
        encoded_data.get(4).unwrap(),
    );
    
    let result = keccak256(encoded_data);
    result
}

#[storage(read)]
fn only_owner() {
    let sender = msg_sender().unwrap();
    if sender != storage.owner.read() {
        revert(0);
    }
}


impl courseMarketplaceContract for Contract {
    
    #[storage(read, write)]
    fn constructor() {
        let sender = msg_sender().unwrap();
        storage.owner.write(sender);
    }

    #[payable]
    #[storage(read, write)]
    fn purchase_course(courseId: b256, proof: b256) -> b256 {
        require_not_paused();

        let sender = msg_sender().unwrap();
        let mut sender: b256 = match sender {
            Identity::Address(address) => address.into(),
            Identity::ContractId(contract_id) => contract_id.into(),
        };
        
        let courseHash: b256 = get_keccak(courseId);

        require(
            has_course_ownership(courseHash),
            CourseMarketplaceError::SenderIsNotCourseOwner
        );

        let id: u64 = storage.totalOwnedCourses.read()+1;
        let amount: u64 = msg_amount();
        storage.ownedCourseHash.insert(id, courseHash);
        let course = Course::new(
            id,
            amount,
            proof,
            sender,
        );
        storage.ownedCourses.insert(courseHash, course);
        
        courseHash
    }

    #[payable]
    #[storage(read)]
    fn repurchase_course(courseHash: b256) -> b256 {
        require_not_paused();

        require(
            has_course_ownership(courseHash),
            CourseMarketplaceError::SenderIsNotCourseOwner
        );

        require (
            is_course_created(courseHash),
            CourseMarketplaceError::CourseIsNotCreated
        );

        let course = storage.ownedCourses.get(courseHash).try_read();

        let mut course = course.unwrap();

        require (
            course.state != CourseState::Deactivated,
            CourseMarketplaceError::InvalidState
        );

        course.state = CourseState::Purchased;
        course.price = msg_amount();

        courseHash
    }

    #[storage(read)]
    fn activate_course(courseHash: b256) -> b256 {
        only_owner();
        require_not_paused();
        
        require (
            is_course_created(courseHash),
            CourseMarketplaceError::CourseIsNotCreated
        );

        let course = storage.ownedCourses.get(courseHash).try_read();

        let mut course = course.unwrap();

        require(
            course.state == CourseState::Purchased,
            CourseMarketplaceError::InvalidState
        );

        course.state = CourseState::Activated;
        courseHash
    }

    #[storage(read)]
    fn deactivate_course(courseHash: b256) -> b256 {
        only_owner();
        require_not_paused();
        
        require(
            is_course_created(courseHash),
            CourseMarketplaceError::CourseIsNotCreated
        );
        

        let course = storage.ownedCourses.get(courseHash).try_read();
        let mut course = course.unwrap();

        require(
            course.state == CourseState::Purchased,
            CourseMarketplaceError::InvalidState
        );

        let amount: u64 = course.price;

        course.state = CourseState::Deactivated;
        course.price = 0;

        transfer(msg_sender().unwrap(), AssetId::base(), amount);
        courseHash
    }

    #[storage(read)]
    fn withdraw(amount_to_withdraw: u64) -> u64 {
        only_owner();
        
        let amount = this_balance(AssetId::base());
        require(
            amount >= amount_to_withdraw,
            CourseMarketplaceError::InvalidAmount
        );

        transfer(storage.owner.read(), AssetId::base(), amount_to_withdraw);

        amount_to_withdraw
    }

    #[storage(read)]
    fn emergency_withdraw() -> u64{
        only_owner();

        let amount = this_balance(AssetId::base());
        require(
            amount > 0,
            CourseMarketplaceError::InvalidAmount
        );

        transfer(storage.owner.read(), AssetId::base(), amount);
        amount
    }

    #[storage(read)]
    fn get_contract_count() -> u64 {
        storage.totalOwnedCourses.read()
    }

    #[storage(read)]
    fn get_course_hash(index: u64) -> b256 {
        let courseHash = storage.ownedCourseHash.get(index).try_read();
        courseHash.unwrap()
    }
    
    #[storage(read)]
    fn owner() -> Identity {
        storage.owner.read()
    }
    
}