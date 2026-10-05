//
//  AuthRepository.swift
//  Xplora
//

protocol AuthRepository {
    /// Returns `nil` when no user is stored; throws when a stored user can't be read.
    func getCurrentUser() throws -> AuthUser?
    @discardableResult
    func completeOnboarding(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) throws -> AuthUser
    func updateName(_ name: String) throws
    func updateResidenceCountry(_ residenceCountryCode: String?) throws
    func logout()
}
