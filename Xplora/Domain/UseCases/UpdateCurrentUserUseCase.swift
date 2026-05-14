//
//  UpdateCurrentUserUseCase.swift
//  Xplora
//

protocol UpdateCurrentUserUseCase {
    func execute(name: String)
}

final class UpdateCurrentUserUseCaseImpl: UpdateCurrentUserUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute(name: String) {
        authRepository.updateName(name)
    }
}
