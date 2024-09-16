library;

pub enum CourseMarketplaceError {
    InvalidState: (),
    CourseIsNotCreated: (),
    CourseHasOwner: (),
    SenderIsNotCourseOwner: (),
    TransferFailed: (),
    InvalidAmount: (),
}