// AddWishlistCountryUseCase.swift
// Xplora

import Foundation

protocol AddWishlistCountryUseCase {
    func execute(_ country: WishlistCountry, force: Bool) async throws -> WishlistAddResult
}

extension AddWishlistCountryUseCase {
    func execute(_ country: WishlistCountry) async throws -> WishlistAddResult {
        try await execute(country, force: false)
    }
}

// MARK: - Implementation

final class AddWishlistCountryUseCaseImpl: AddWishlistCountryUseCase {
    private let repo: WishlistRepo

    init(repo: WishlistRepo) {
        self.repo = repo
    }

    func execute(_ country: WishlistCountry, force: Bool) async throws -> WishlistAddResult {
        let existing = try await repo.getAll()

        if existing.contains(where: { isExactDuplicate($0, country) }) {
            return .exactDuplicate
        }

        if !force {
            let sameCountry = existing.filter { $0.code == country.code }
            let newHasCity = country.cityIdentity != .none
            let hasCountryOnly = sameCountry.contains { $0.cityIdentity == .none }
            let hasCities = sameCountry.contains { $0.cityIdentity != .none }

            if newHasCity && hasCountryOnly {
                return .needsConfirmation(.countryAlreadyExistsWithoutCity)
            }
            if !newHasCity && hasCities {
                return .needsConfirmation(.countryAlreadyHasCities)
            }
        }

        try await repo.add(country)
        return .added
    }

    private func isExactDuplicate(_ a: WishlistCountry, _ b: WishlistCountry) -> Bool {
        a.code == b.code && a.cityIdentity == b.cityIdentity
    }
}
