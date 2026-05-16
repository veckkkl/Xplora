//
//  SearchCitiesUseCase.swift
//  Xplora
//

import Foundation

protocol SearchCitiesUseCase {
    func execute(query: String) async throws -> [CatalogCity]
}

final class SearchCitiesUseCaseImpl: SearchCitiesUseCase {
    private let repo: CitiesCatalogRepo

    init(repo: CitiesCatalogRepo) {
        self.repo = repo
    }

    func execute(query: String) async throws -> [CatalogCity] {
        try await repo.search(query: query)
    }
}
