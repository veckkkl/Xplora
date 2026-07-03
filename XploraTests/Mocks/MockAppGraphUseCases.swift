//
//  MockAppGraphUseCases.swift
//  XploraTests
//
//  Lightweight stubs for every use case AppCoordinator resolves while building
//  the main tab bar, so routing can be exercised without touching network,
//  CoreData or CoreLocation.
//

import Foundation
@testable import Xplora

final class MockGetWishlistCountriesUseCase: GetWishlistCountriesUseCase {
    func execute() async throws -> [WishlistCountry] { [] }
}

final class MockAddWishlistCountryUseCase: AddWishlistCountryUseCase {
    func execute(_ country: WishlistCountry, force: Bool) async throws -> WishlistAddResult { .added }
}

final class MockRemoveWishlistCountryUseCase: RemoveWishlistCountryUseCase {
    func execute(id: UUID) async throws {}
}

final class MockToggleWishlistCountryUseCase: ToggleWishlistCountryUseCase {
    func execute(id: UUID) async throws {}
}

final class MockGetCatalogPlacesUseCase: GetCatalogPlacesUseCase {
    var stubbedPlaces: [CatalogPlace] = []
    func execute() async throws -> [CatalogPlace] { stubbedPlaces }
}

final class MockGetCitiesForPlaceUseCase: GetCitiesForPlaceUseCase {
    func execute(placeCode: String) async throws -> [CatalogCity] { [] }
}

final class MockDeleteTripUseCase: DeleteTripUseCase {
    func execute(tripId: UUID) async throws {}
}

final class MockGetNoteUseCase: GetNoteUseCase {
    func execute(id: String) async throws -> Note { throw NoteRepositoryError.notFound }
}

final class MockGetAllNotesUseCase: GetAllNotesUseCase {
    func execute() async throws -> [Note] { [] }
}

final class MockSaveNoteUseCase: SaveNoteUseCase {
    func execute(note: Note) async throws -> Note { note }
}

final class MockDeleteNoteUseCase: DeleteNoteUseCase {
    func execute(noteId: String) async throws {}
}

final class MockLocationService: LocationService {
    func requestWhenInUseAuthorization() {}
    func startUpdatingLocation() {}
    func requestCurrentLocation() async throws -> LocationCoordinate {
        LocationCoordinate(latitude: 0, longitude: 0)
    }
}

final class MockResetUserDataUseCase: ResetUserDataUseCase {
    private(set) var executeCallCount = 0
    func execute() async { executeCallCount += 1 }
}
