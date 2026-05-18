//
//  CompleteOnboardingUseCase.swift
//  Xplora
//

protocol CompleteOnboardingUseCase {
    @discardableResult
    func execute(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser
}

final class CompleteOnboardingUseCaseImpl: CompleteOnboardingUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    @discardableResult
    func execute(name: String, residenceCountryCode: String?, isWorldCitizen: Bool) -> AuthUser {
        authRepository.completeOnboarding(name: name, residenceCountryCode: residenceCountryCode, isWorldCitizen: isWorldCitizen)
    }
}
