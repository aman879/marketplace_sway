library;

pub enum CourseState {
    Purchased: (),
    Activated: (),
    Deactivated: (),
}

impl core::ops::Eq for CourseState {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (CourseState::Purchased, CourseState::Purchased) => true,
            (CourseState::Activated, CourseState::Activated) => true,
            (CourseState::Deactivated, CourseState::Deactivated) => true,
            _ => false,
        }
    }
}