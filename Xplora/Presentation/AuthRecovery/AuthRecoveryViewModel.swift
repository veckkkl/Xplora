//
//  AuthRecoveryViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol AuthRecoveryViewModelInput: AnyObject {
    func didTapRetry()
    func didConfirmReset()
}

@MainActor
protocol AuthRecoveryViewModelOutput: AnyObject {
    /// The user could be read (or turned out to be missing) — leave recovery.
    var onRoute: ((AppLaunchRoute) -> Void)? { get set }
    var onRetryFailed: ((String) -> Void)? { get set }
    var onResetInProgress: ((Bool) -> Void)? { get set }
    var onResetFailed: ((String) -> Void)? { get set }
    /// All local data is gone; the app should start over from onboarding.
    var onResetCompleted: (() -> Void)? { get set }
}

@MainActor
final class AuthRecoveryViewModel: AuthRecoveryViewModelInput, AuthRecoveryViewModelOutput {
    var onRoute: ((AppLaunchRoute) -> Void)?
    var onRetryFailed: ((String) -> Void)?
    var onResetInProgress: ((Bool) -> Void)?
    var onResetFailed: ((String) -> Void)?
    var onResetCompleted: (() -> Void)?

    private let getCurrentUser: GetCurrentUserUseCase
    private let deleteAllUserData: DeleteAllUserDataUseCase

    init(getCurrentUser: GetCurrentUserUseCase, deleteAllUserData: DeleteAllUserDataUseCase) {
        self.getCurrentUser = getCurrentUser
        self.deleteAllUserData = deleteAllUserData
    }

    func didTapRetry() {
        let route = AppLaunchRouteResolver.resolve(getCurrentUser: getCurrentUser)
        if route == .authRecovery {
            onRetryFailed?(L10n.Auth.Recovery.retryFailed)
        } else {
            onRoute?(route)
        }
    }

    func didConfirmReset() {
        Task { await reset() }
    }

    func reset() async {
        onResetInProgress?(true)
        do {
            try await deleteAllUserData.execute()
            onResetInProgress?(false)
            onResetCompleted?()
        } catch {
            // Partial failure: the corrupted user is kept, so recovery stays.
            onResetInProgress?(false)
            onResetFailed?(L10n.Profile.Delete.errorMessage)
        }
    }
}
