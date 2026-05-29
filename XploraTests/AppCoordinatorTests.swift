//
//  AppCoordinatorTests.swift
//  XploraTests
//

import Foundation
import UIKit
import Testing
@testable import Xplora

@MainActor
@Suite(.serialized)
struct AppCoordinatorTests {

    private func makeUser(name: String = "Auth User") -> AuthUser {
        AuthUser(id: "id", name: name, createdAt: Date(), residenceCountryCode: "US", isWorldCitizen: false)
    }

    private func makeWindow() -> UIWindow {
        UIWindow(frame: UIScreen.main.bounds)
    }

    /// Registers a complete mock graph so AppCoordinator can build either the
    /// onboarding screen or the full main tab bar without real I/O.
    private func makeLocator(currentUser: AuthUser?) -> (
        locator: ServiceLocator,
        getCurrentUser: MockGetCurrentUserUseCase,
        reset: MockResetUserDataUseCase
    ) {
        let locator = ServiceLocator()
        let getCurrentUser = MockGetCurrentUserUseCase()
        getCurrentUser.stubbedUser = currentUser
        let reset = MockResetUserDataUseCase()

        locator.register(GetCurrentUserUseCase.self, instance: getCurrentUser)
        locator.register(CompleteOnboardingUseCase.self, instance: MockCompleteOnboardingUseCase())
        locator.register(ResetUserDataUseCase.self, instance: reset)
        locator.register(GetCatalogPlacesUseCase.self, instance: MockGetCatalogPlacesUseCase())
        locator.register(GetWishlistCountriesUseCase.self, instance: MockGetWishlistCountriesUseCase())
        locator.register(AddWishlistCountryUseCase.self, instance: MockAddWishlistCountryUseCase())
        locator.register(RemoveWishlistCountryUseCase.self, instance: MockRemoveWishlistCountryUseCase())
        locator.register(ToggleWishlistCountryUseCase.self, instance: MockToggleWishlistCountryUseCase())
        locator.register(GetCitiesForPlaceUseCase.self, instance: MockGetCitiesForPlaceUseCase())
        locator.register(GetStatisticsUseCase.self, instance: MockGetStatisticsUseCase())
        locator.register(UpdateCurrentUserUseCase.self, instance: MockUpdateCurrentUserUseCase())
        locator.register(GetTripsUseCase.self, instance: MockGetTripsUseCase())
        locator.register(DeleteTripUseCase.self, instance: MockDeleteTripUseCase())
        locator.register(GetNoteUseCase.self, instance: MockGetNoteUseCase())
        locator.register(GetAllNotesUseCase.self, instance: MockGetAllNotesUseCase())
        locator.register(SaveNoteUseCase.self, instance: MockSaveNoteUseCase())
        locator.register(DeleteNoteUseCase.self, instance: MockDeleteNoteUseCase())
        locator.register(LocationService.self, instance: MockLocationService())
        locator.register(FogOverlayProviding.self, instance: EmptyFogOverlayProvider())

        return (locator, getCurrentUser, reset)
    }

    private func onboardingRoot(of window: UIWindow) -> OnboardingViewController? {
        (window.rootViewController as? UINavigationController)?.viewControllers.first as? OnboardingViewController
    }

    // MARK: - start()

    @Test func start_noUser_showsOnboarding() {
        let (locator, _, _) = makeLocator(currentUser: nil)
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.start()
        #expect(onboardingRoot(of: window) != nil)
    }

    @Test func start_withUser_showsMainApp() {
        let (locator, _, _) = makeLocator(currentUser: makeUser())
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.start()
        #expect(window.rootViewController is MainTabBarController)
    }

    // MARK: - showOnboarding()

    @Test func showOnboarding_setsHiddenNavOnboardingRoot() {
        let (locator, _, _) = makeLocator(currentUser: nil)
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.showOnboarding()
        let nav = window.rootViewController as? UINavigationController
        #expect(nav?.viewControllers.first is OnboardingViewController)
        #expect(nav?.isNavigationBarHidden == true)
    }

    // MARK: - handleOnboardingCompleted()

    @Test func handleOnboardingCompleted_showsMainAppAndSyncsName() {
        ProfileUserSettings.reset()
        let (locator, _, _) = makeLocator(currentUser: makeUser(name: "SyncedName"))
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.handleOnboardingCompleted()
        #expect(window.rootViewController is MainTabBarController)
        #expect(ProfileUserSettings.currentName == "SyncedName")
        ProfileUserSettings.reset()
    }

    // MARK: - handleLogout()

    @Test func handleLogout_returnsToOnboarding() {
        let (locator, _, _) = makeLocator(currentUser: makeUser())
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.showMainApp()
        sut.handleLogout()
        #expect(onboardingRoot(of: window) != nil)
    }

    @Test func handleLogout_triggersUserDataReset() async {
        let (locator, _, reset) = makeLocator(currentUser: makeUser())
        let window = makeWindow()
        let sut = AppCoordinator(window: window, locator: locator)
        sut.handleLogout()
        // handleLogout fires the reset in an unstructured Task; let it run.
        for _ in 0..<100 where reset.executeCallCount == 0 {
            await Task.yield()
        }
        #expect(reset.executeCallCount == 1)
    }
}
