//
//  AuthRepositoryImpl.swift
//  Xplora
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private enum Keys {
        static let currentUser = "auth.current_user"
    }

    private let storage: LocalStorageProtocol

    init(storage: LocalStorageProtocol) {
        self.storage = storage
    }

    func getCurrentUser() -> AuthUser? {
        storage.load(AuthUser.self, forKey: Keys.currentUser)
    }

    @discardableResult
    func completeOnboarding(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser {
        let user = AuthUser(
            id: UUID().uuidString,
            name: name,
            createdAt: Date(),
            residenceCountryCode: residenceCountryCode,
            isWorldCitizen: isWorldCitizen
        )
        storage.save(user, forKey: Keys.currentUser)
        return user
    }

    func updateName(_ name: String) {
        guard let user = getCurrentUser() else { return }
        let updated = AuthUser(
            id: user.id,
            name: name,
            createdAt: user.createdAt,
            residenceCountryCode: user.residenceCountryCode,
            isWorldCitizen: user.isWorldCitizen
        )
        storage.save(updated, forKey: Keys.currentUser)
    }

    func logout() {
        storage.removeValue(forKey: Keys.currentUser)
    }
}
