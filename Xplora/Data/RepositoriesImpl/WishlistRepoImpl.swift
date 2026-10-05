// WishlistRepoImpl.swift
// Xplora

import Foundation

final class WishlistRepoImpl: WishlistRepo {
    private let storage: LocalStorageProtocol

    init(storage: LocalStorageProtocol) {
        self.storage = storage
    }

    func getAll() async throws -> [WishlistCountry] {
        try storage.loadWishlistCountries()
    }

    func add(_ country: WishlistCountry) async throws {
        var list = try storage.loadWishlistCountries()
        list.append(country)
        try storage.saveWishlistCountries(list)
    }

    func remove(id: UUID) async throws {
        var list = try storage.loadWishlistCountries()
        list.removeAll { $0.id == id }
        try storage.saveWishlistCountries(list)
    }

    func toggle(id: UUID) async throws {
        var list = try storage.loadWishlistCountries()
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        list[index].isCompleted.toggle()
        try storage.saveWishlistCountries(list)
    }

    func removeAll() async throws {
        storage.removeWishlistCountries()
    }
}
