//
//  GetCatalogPlacesUseCase.swift
//  Xplora
//

import Foundation

protocol GetCatalogPlacesUseCase {
    func execute() async throws -> [CatalogPlace]
}

final class GetCatalogPlacesUseCaseImpl: GetCatalogPlacesUseCase {
    private let repo: CatalogPlacesRepo

    init(repo: CatalogPlacesRepo) {
        self.repo = repo
    }

    func execute() async throws -> [CatalogPlace] {
        try await repo.getAll()
    }
}
