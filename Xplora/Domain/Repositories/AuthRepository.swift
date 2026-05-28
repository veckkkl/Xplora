//
//  AuthRepository.swift
//  Xplora
//

protocol AuthRepository {
    func getCurrentUser() -> AuthUser?
    @discardableResult
    func completeOnboarding(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser
    func updateName(_ name: String)
    func updateResidenceCountry(_ residenceCountryCode: String?)
    func logout()
}
