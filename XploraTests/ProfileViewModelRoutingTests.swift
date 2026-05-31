//
//  ProfileViewModelRoutingTests.swift
//  XploraTests
//

import Testing
import Foundation
@testable import Xplora

@MainActor
struct ProfileViewModelRoutingTests {

    private func makeUser(
        name: String = "Auth User",
        residenceCountryCode: String? = nil
    ) -> AuthUser {
        AuthUser(
            id: "test-id",
            name: name,
            createdAt: Date(),
            residenceCountryCode: residenceCountryCode,
            isWorldCitizen: false
        )
    }

    private struct SUT {
        let viewModel: ProfileViewModel
        let getUser: MockGetCurrentUserUseCase
        let updateUser: MockUpdateCurrentUserUseCase
        let statistics: MockGetStatisticsUseCase
        let trips: MockGetTripsUseCase
    }

    private func makeSUT(user: AuthUser? = nil) -> SUT {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedUser = user
        let updateUser = MockUpdateCurrentUserUseCase()
        let statistics = MockGetStatisticsUseCase()
        let trips = MockGetTripsUseCase()
        let vm = ProfileViewModel(
            getCurrentUser: getUser,
            updateCurrentUser: updateUser,
            getStatistics: statistics,
            getTrips: trips
        )
        return SUT(viewModel: vm, getUser: getUser, updateUser: updateUser, statistics: statistics, trips: trips)
    }

    private enum SectionIndex {
        static let profileCard = 0
        static let appearance = 1
        static let app = 2
        static let data = 3
    }

    // MARK: - No-user routing

    @Test func viewDidLoad_noUser_routeIsLogoutExactlyOnce() {
        let sut = makeSUT(user: nil)
        var routes: [ProfileRoute] = []
        sut.viewModel.onRoute = { routes.append($0) }
        sut.viewModel.viewDidLoad()
        #expect(routes == [.logout])
    }

    @Test func viewDidLoad_noUser_doesNotInvokeUpdateUseCase() {
        let sut = makeSUT(user: nil)
        sut.viewModel.viewDidLoad()
        #expect(sut.updateUser.callCount == 0)
        #expect(sut.updateUser.residenceCallCount == 0)
    }

    // MARK: - Profile card tap

    @Test func didSelectProfileCard_emitsOpenProfileDetailsWithCurrentResidence() {
        let sut = makeSUT(user: makeUser(residenceCountryCode: "DE"))
        sut.viewModel.viewDidLoad()
        var captured: ProfileRoute?
        sut.viewModel.onRoute = { captured = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 0, section: SectionIndex.profileCard))

        guard case .openProfileDetails(let status, let residenceCountryCode) = captured else {
            Issue.record("Expected .openProfileDetails route, got \(String(describing: captured))")
            return
        }
        #expect(status == .adventureTraveler)
        #expect(residenceCountryCode == "DE")
    }

    @Test func didSelectProfileCard_nilResidence_propagatedAsNil() {
        let sut = makeSUT(user: makeUser(residenceCountryCode: nil))
        sut.viewModel.viewDidLoad()
        var captured: ProfileRoute?
        sut.viewModel.onRoute = { captured = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 0, section: SectionIndex.profileCard))

        guard case .openProfileDetails(_, let residenceCountryCode) = captured else {
            Issue.record("Expected .openProfileDetails route")
            return
        }
        #expect(residenceCountryCode == nil)
    }

    // MARK: - Action rows → routes

    @Test func selectLanguageItem_emitsOpenLanguageSelection() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        // appearance section, row 1 = language (row 0 is darkTheme toggle)
        sut.viewModel.didSelectItem(at: IndexPath(row: 1, section: SectionIndex.appearance))
        #expect(route == .openLanguageSelection)
    }

    @Test func selectDarkThemeItem_doesNotEmitRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        // appearance section, row 0 = darkTheme toggle → handled inline, no route
        sut.viewModel.didSelectItem(at: IndexPath(row: 0, section: SectionIndex.appearance))
        #expect(route == nil)
    }

    @Test func selectShareItem_emitsShareAppRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 0, section: SectionIndex.app))
        #expect(route == .shareApp)
    }

    @Test func selectRateAppItem_emitsRateAppRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 1, section: SectionIndex.app))
        #expect(route == .rateApp)
    }

    @Test func selectAboutItem_emitsOpenAboutXploraRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 2, section: SectionIndex.app))
        #expect(route == .openAboutXplora)
    }

    @Test func selectPrivacyPolicyItem_emitsOpenPrivacyPolicyRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var route: ProfileRoute?
        sut.viewModel.onRoute = { route = $0 }
        sut.viewModel.didSelectItem(at: IndexPath(row: 3, section: SectionIndex.app))
        #expect(route == .openPrivacyPolicy)
    }

    // MARK: - Out-of-bounds safety

    @Test func didSelectItem_invalidSection_doesNothing() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var routeFired = false
        sut.viewModel.onRoute = { _ in routeFired = true }
        sut.viewModel.didSelectItem(at: IndexPath(row: 0, section: 99))
        #expect(routeFired == false)
    }

    @Test func didSelectItem_invalidRow_doesNothing() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var routeFired = false
        sut.viewModel.onRoute = { _ in routeFired = true }
        sut.viewModel.didSelectItem(at: IndexPath(row: 99, section: SectionIndex.appearance))
        #expect(routeFired == false)
    }

    // MARK: - Mutations should not emit routes

    @Test func didUpdateUserName_doesNotEmitRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var routeFired = false
        sut.viewModel.onRoute = { _ in routeFired = true }
        sut.viewModel.didUpdateUserName("New Name")
        #expect(routeFired == false)
    }

    @Test func didUpdateResidenceCountry_doesNotEmitRoute() {
        let sut = makeSUT(user: makeUser())
        sut.viewModel.viewDidLoad()
        var routeFired = false
        sut.viewModel.onRoute = { _ in routeFired = true }
        sut.viewModel.didUpdateResidenceCountry("FR")
        #expect(routeFired == false)
    }
}
