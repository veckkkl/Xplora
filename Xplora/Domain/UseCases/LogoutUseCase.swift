//
//  LogoutUseCase.swift
//  Xplora
//

protocol LogoutUseCase {
    func execute()
}

final class LogoutUseCaseImpl: LogoutUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute() {
        authRepository.logout()
    }
}
