// WishlistRepo.swift
// Xplora

import Foundation

protocol WishlistRepo {
    func getAll() async throws -> [WishlistCountry]
    func add(_ country: WishlistCountry) async throws
    func remove(id: UUID) async throws
    func toggle(id: UUID) async throws
}
