library;

use ::data_structure::state::CourseState;

pub struct Course {
    pub id: u64,
    pub price: u64,
    pub proof: b256,
    pub owner: b256,
    pub state: CourseState,
}

impl Course {
    pub fn new(
        id: u64,
        price: u64,
        proof: b256,
        owner: b256,
    ) -> Self {
        Course {
            id,
            price,
            proof,
            owner,
            state: CourseState::Purchased,
        }
    }
}