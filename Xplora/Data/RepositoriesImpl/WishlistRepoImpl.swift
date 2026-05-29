// WishlistRepoImpl.swift
// Xplora

import Foundation

final class WishlistRepoImpl: WishlistRepo {
    private let storage: LocalStorageProtocol

    init(storage: LocalStorageProtocol) {
        self.storage = storage
    }

    func getAll() async throws -> [WishlistCountry] {
        storage.wishlistCountries
    }

    func add(_ country: WishlistCountry) async throws {
        var list = storage.wishlistCountries
        list.append(country)
        storage.wishlistCountries = list
    }

    func remove(id: UUID) async throws {
        var list = storage.wishlistCountries
        list.removeAll { $0.id == id }
        storage.wishlistCountries = list
    }

    func toggle(id: UUID) async throws {
        var list = storage.wishlistCountries
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        list[index].isCompleted.toggle()
        storage.wishlistCountries = list
    }

    func deleteAll() async throws {
        storage.wishlistCountries = []
    }
}
