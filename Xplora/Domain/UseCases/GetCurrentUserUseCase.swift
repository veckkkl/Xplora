//
//  GetCurrentUserUseCase.swift
//  Xplora
//

protocol GetCurrentUserUseCase {
    func execute() throws -> AuthUser?
}

final class GetCurrentUserUseCaseImpl: GetCurrentUserUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute() throws -> AuthUser? {
        try authRepository.getCurrentUser()
    }
}
