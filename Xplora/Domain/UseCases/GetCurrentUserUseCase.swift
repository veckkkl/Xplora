//
//  GetCurrentUserUseCase.swift
//  Xplora
//

protocol GetCurrentUserUseCase {
    func execute() -> AuthUser?
}

final class GetCurrentUserUseCaseImpl: GetCurrentUserUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute() -> AuthUser? {
        authRepository.getCurrentUser()
    }
}
