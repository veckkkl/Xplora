// RemoveWishlistCountryUseCase.swift
// Xplora

import Foundation

protocol RemoveWishlistCountryUseCase {
    func execute(id: UUID) async throws
}

final class RemoveWishlistCountryUseCaseImpl: RemoveWishlistCountryUseCase {
    private let repo: WishlistRepo

    init(repo: WishlistRepo) {
        self.repo = repo
    }

    func execute(id: UUID) async throws {
        try await repo.remove(id: id)
    }
}
