//
//  GetCitiesForPlaceUseCase.swift
//  Xplora
//

import Foundation

protocol GetCitiesForPlaceUseCase {
    func execute(placeCode: String) async throws -> [CatalogCity]
}

final class GetCitiesForPlaceUseCaseImpl: GetCitiesForPlaceUseCase {
    private let repo: CitiesCatalogRepo

    init(repo: CitiesCatalogRepo) {
        self.repo = repo
    }

    func execute(placeCode: String) async throws -> [CatalogCity] {
        try await repo.cities(forPlaceCode: placeCode)
    }
}
