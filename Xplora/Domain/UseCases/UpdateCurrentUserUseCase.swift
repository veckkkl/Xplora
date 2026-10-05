//
//  UpdateCurrentUserUseCase.swift
//  Xplora
//

protocol UpdateCurrentUserUseCase {
    func execute(name: String) throws
    func execute(residenceCountryCode: String?) throws
}

final class UpdateCurrentUserUseCaseImpl: UpdateCurrentUserUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute(name: String) throws {
        try authRepository.updateName(name)
    }

    func execute(residenceCountryCode: String?) throws {
        try authRepository.updateResidenceCountry(residenceCountryCode)
    }
}
