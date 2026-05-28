//
//  UpdateCurrentUserUseCase.swift
//  Xplora
//

protocol UpdateCurrentUserUseCase {
    func execute(name: String)
    func execute(residenceCountryCode: String?)
}

final class UpdateCurrentUserUseCaseImpl: UpdateCurrentUserUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute(name: String) {
        authRepository.updateName(name)
    }

    func execute(residenceCountryCode: String?) {
        authRepository.updateResidenceCountry(residenceCountryCode)
    }
}
