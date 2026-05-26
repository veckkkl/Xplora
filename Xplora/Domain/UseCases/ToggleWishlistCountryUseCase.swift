// ToggleWishlistCountryUseCase.swift
// Xplora

import Foundation

protocol ToggleWishlistCountryUseCase {
    func execute(id: UUID) async throws
}

final class ToggleWishlistCountryUseCaseImpl: ToggleWishlistCountryUseCase {
    private let repo: WishlistRepo

    init(repo: WishlistRepo) {
        self.repo = repo
    }

    func execute(id: UUID) async throws {
        try await repo.toggle(id: id)
    }
}
