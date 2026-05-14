//
//  AuthRepository.swift
//  Xplora
//

protocol AuthRepository {
    func getCurrentUser() -> AuthUser?
    @discardableResult
    func completeOnboarding(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser
    func updateName(_ name: String)
    func logout()
}
