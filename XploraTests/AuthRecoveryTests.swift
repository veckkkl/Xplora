//
//  AuthRecoveryTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

@MainActor
struct AppLaunchRouteResolverTests {

    private func makeUseCase() -> (GetCurrentUserUseCaseImpl, AuthRepositoryImpl, MockLocalStorage) {
        let storage = MockLocalStorage()
        let repo = AuthRepositoryImpl(storage: storage)
        return (GetCurrentUserUseCaseImpl(authRepository: repo), repo, storage)
    }

    @Test func noStoredUser_routesToOnboarding() {
        let (useCase, _, _) = makeUseCase()
        #expect(AppLaunchRouteResolver.resolve(getCurrentUser: useCase) == .onboarding)
    }

    @Test func readableUser_routesToMainApp() throws {
        let (useCase, repo, _) = makeUseCase()
        try repo.completeOnboarding(name: "Alice", residenceCountryCode: "FR", isWorldCitizen: false)
        #expect(AppLaunchRouteResolver.resolve(getCurrentUser: useCase) == .mainApp)
    }

    @Test func corruptedUser_routesToRecoveryNotOnboarding() {
        let (useCase, _, storage) = makeUseCase()
        let corrupted = Data("{\"id\":".utf8)
        storage.store["auth.current_user"] = corrupted

        #expect(AppLaunchRouteResolver.resolve(getCurrentUser: useCase) == .authRecovery)
        // Reading must not touch the stored record.
        #expect(storage.store["auth.current_user"] == corrupted)
    }
}

@MainActor
struct AuthRecoveryViewModelTests {

    private func user() -> AuthUser {
        AuthUser(id: "id", name: "Alice", createdAt: Date(), residenceCountryCode: nil, isWorldCitizen: true)
    }

    @Test func retry_whenStillUnreadable_staysInRecovery() {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedError = CocoaError(.coderReadCorrupt)
        let sut = AuthRecoveryViewModel(getCurrentUser: getUser, deleteAllUserData: MockDeleteAllUserDataUseCase())
        var routes: [AppLaunchRoute] = []
        var retryFailed: String?
        sut.onRoute = { routes.append($0) }
        sut.onRetryFailed = { retryFailed = $0 }

        sut.didTapRetry()

        #expect(routes.isEmpty)
        #expect(retryFailed == L10n.Auth.Recovery.retryFailed)
    }

    @Test func retry_whenReadable_routesToMainApp() {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedUser = user()
        let sut = AuthRecoveryViewModel(getCurrentUser: getUser, deleteAllUserData: MockDeleteAllUserDataUseCase())
        var routes: [AppLaunchRoute] = []
        sut.onRoute = { routes.append($0) }

        sut.didTapRetry()

        #expect(routes == [.mainApp])
    }

    @Test func reset_success_completes() async {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedError = CocoaError(.coderReadCorrupt)
        let deleteAll = MockDeleteAllUserDataUseCase()
        let sut = AuthRecoveryViewModel(getCurrentUser: getUser, deleteAllUserData: deleteAll)
        var completed = false
        sut.onResetCompleted = { completed = true }

        await sut.reset()

        #expect(deleteAll.callCount == 1)
        #expect(completed)
    }

    @Test func reset_failure_reportsErrorAndDoesNotComplete() async {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedError = CocoaError(.coderReadCorrupt)
        let deleteAll = MockDeleteAllUserDataUseCase()
        deleteAll.stubbedError = DeleteAllUserDataError.partialFailure(failed: [.notes])
        let sut = AuthRecoveryViewModel(getCurrentUser: getUser, deleteAllUserData: deleteAll)
        var completed = false
        var failure: String?
        sut.onResetCompleted = { completed = true }
        sut.onResetFailed = { failure = $0 }

        await sut.reset()

        #expect(!completed)
        #expect(failure == L10n.Profile.Delete.errorMessage)
    }
}
