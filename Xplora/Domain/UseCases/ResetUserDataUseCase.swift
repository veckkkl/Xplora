//
//  ResetUserDataUseCase.swift
//  Xplora
//

protocol ResetUserDataUseCase {
    func execute() async
}

/// Wipes all locally stored user data: the authenticated user (which gates
/// onboarding), trips, wishlist and notes. Each step is best-effort so a
/// failure in one store does not prevent clearing the others.
final class ResetUserDataUseCaseImpl: ResetUserDataUseCase {
    private let logout: LogoutUseCase
    private let tripsRepo: TripsRepo
    private let wishlistRepo: WishlistRepo
    private let notesRepo: NotesRepo

    init(
        logout: LogoutUseCase,
        tripsRepo: TripsRepo,
        wishlistRepo: WishlistRepo,
        notesRepo: NotesRepo
    ) {
        self.logout = logout
        self.tripsRepo = tripsRepo
        self.wishlistRepo = wishlistRepo
        self.notesRepo = notesRepo
    }

    func execute() async {
        logout.execute()
        try? await tripsRepo.deleteAll()
        try? await wishlistRepo.deleteAll()
        try? await notesRepo.deleteAll()
    }
}
