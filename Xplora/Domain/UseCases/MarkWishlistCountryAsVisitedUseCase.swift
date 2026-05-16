//
//  MarkWishlistCountryAsVisitedUseCase.swift
//  Xplora
//

import Foundation

enum WishlistUseCaseError: Error {
    case countryNotInWishlist
}

protocol MarkWishlistCountryAsVisitedUseCase {
    func execute(countryCode: String) async throws
}

final class MarkWishlistCountryAsVisitedUseCaseImpl: MarkWishlistCountryAsVisitedUseCase {
    private let wishlistRepo: WishlistRepo

    init(wishlistRepo: WishlistRepo) {
        self.wishlistRepo = wishlistRepo
    }

    func execute(countryCode: String) async throws {
        let items = try await wishlistRepo.getAll()
        guard let item = items.first(where: { $0.code == countryCode && !$0.isCompleted }) else {
            throw WishlistUseCaseError.countryNotInWishlist
        }
        try await wishlistRepo.toggle(id: item.id)
    }
}
