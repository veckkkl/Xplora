// GetWishlistCountriesUseCase.swift
// Xplora

import Foundation

protocol GetWishlistCountriesUseCase {
    func execute() async throws -> [WishlistCountry]
}

final class GetWishlistCountriesUseCaseImpl: GetWishlistCountriesUseCase {
    private let repo: WishlistRepo

    init(repo: WishlistRepo) {
        self.repo = repo
    }

    func execute() async throws -> [WishlistCountry] {
        try await repo.getAll()
    }
}
