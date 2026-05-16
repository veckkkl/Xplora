//
//  GetCountriesCatalogUseCase.swift
//  Xplora
//

import Foundation

protocol GetCountriesCatalogUseCase {
    func execute() async throws -> [CatalogCountry]
}

final class GetCountriesCatalogUseCaseImpl: GetCountriesCatalogUseCase {
    private let repo: CountriesCatalogRepo

    init(repo: CountriesCatalogRepo) {
        self.repo = repo
    }

    func execute() async throws -> [CatalogCountry] {
        try await repo.getAll()
    }
}
