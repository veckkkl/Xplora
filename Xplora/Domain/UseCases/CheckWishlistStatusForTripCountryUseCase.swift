//
//  CheckWishlistStatusForTripCountryUseCase.swift
//  Xplora
//

import Foundation

protocol CheckWishlistStatusForTripCountryUseCase {
    /// Returns true if the country is in the wishlist and not yet completed.
    func execute(countryCode: String) async throws -> Bool
}

final class CheckWishlistStatusForTripCountryUseCaseImpl: CheckWishlistStatusForTripCountryUseCase {
    private let wishlistRepo: WishlistRepo

    init(wishlistRepo: WishlistRepo) {
        self.wishlistRepo = wishlistRepo
    }

    func execute(countryCode: String) async throws -> Bool {
        let items = try await wishlistRepo.getAll()
        return items.contains { $0.code == countryCode && !$0.isCompleted }
    }
}
