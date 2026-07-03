//
//  ProfileViewModelTests.swift
//  XploraTests
//

import Testing
import Foundation
import UIKit
@testable import Xplora

@MainActor
struct ProfileViewModelTests {

    private func makeUser(name: String = "Auth User") -> AuthUser {
        AuthUser(id: "test-id", name: name, createdAt: Date(), residenceCountryCode: nil, isWorldCitizen: false)
    }

    private func makeSUT(
        user: AuthUser? = nil
    ) -> (sut: ProfileViewModel, getUser: MockGetCurrentUserUseCase, updateUser: MockUpdateCurrentUserUseCase) {
        let getUser = MockGetCurrentUserUseCase()
        getUser.stubbedUser = user
        let updateUser = MockUpdateCurrentUserUseCase()
        let sut = ProfileViewModel(
            getCurrentUser: getUser,
            updateCurrentUser: updateUser,
            getStatistics: MockGetStatisticsUseCase(),
            getTrips: MockGetTripsUseCase()
        )
        return (sut, getUser, updateUser)
    }

    // MARK: - viewDidLoad

    @Test func viewDidLoad_userExists_firesSectionsChange() {
        let (sut, _, _) = makeSUT(user: makeUser())
        var sectionsReceived = false
        sut.onSectionsChange = { _ in sectionsReceived = true }
        sut.viewDidLoad()
        #expect(sectionsReceived == true)
    }

    @Test func viewDidLoad_noUser_firesLogoutRoute() {
        let (sut, _, _) = makeSUT(user: nil)
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        sut.viewDidLoad()
        #expect(route == .logout)
    }

    @Test func viewDidLoad_noUser_doesNotFireSectionsChange() {
        let (sut, _, _) = makeSUT(user: nil)
        var sectionsReceived = false
        sut.onSectionsChange = { _ in sectionsReceived = true }
        sut.viewDidLoad()
        #expect(sectionsReceived == false)
    }

    // MARK: - Name source

    @Test func viewDidLoad_userNameComesFromAuthUser() {
        let (sut, _, _) = makeSUT(user: makeUser(name: "Auth Name"))
        var sections: [ProfileSectionModel] = []
        sut.onSectionsChange = { sections = $0 }
        sut.viewDidLoad()
        let cardSection = sections.first(where: { $0.section == .profileCard })
        guard case .profileCard(let item) = cardSection?.items.first else {
            Issue.record("Expected profileCard item")
            return
        }
        #expect(item.name == "Auth Name")
    }

    // MARK: - didUpdateUserName

    @Test func didUpdateUserName_callsUpdateUseCase() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didUpdateUserName("New Name")
        #expect(updateUser.callCount == 1)
        #expect(updateUser.updatedName == "New Name")
    }

    @Test func didUpdateUserName_triggersSectionsRefresh() {
        let (sut, getUser, _) = makeSUT(user: makeUser(name: "Old"))
        sut.viewDidLoad()
        getUser.stubbedUser = makeUser(name: "New Name")
        var sections: [ProfileSectionModel] = []
        sut.onSectionsChange = { sections = $0 }
        sut.didUpdateUserName("New Name")
        let cardSection = sections.first(where: { $0.section == .profileCard })
        guard case .profileCard(let item) = cardSection?.items.first else {
            Issue.record("Expected profileCard item")
            return
        }
        #expect(item.name == "New Name")
    }

    // MARK: - Data section

    @Test func selectDeleteDataItem_firesConfirmDeleteRoute() {
        let (sut, _, _) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        // Data section is index 3, delete-data row is index 0
        sut.didSelectItem(at: IndexPath(row: 0, section: 3))
        #expect(route == .confirmDeleteData)
    }

    @Test func selectDeleteDataItem_doesNotCallUpdateUseCase() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didSelectItem(at: IndexPath(row: 0, section: 3))
        #expect(updateUser.callCount == 0)
    }

    @Test func didConfirmDeleteData_firesLogoutRoute() {
        let (sut, _, _) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        sut.didConfirmDeleteData()
        #expect(route == .logout)
    }

    // MARK: - didToggleDarkTheme

    @Test func didToggleDarkTheme_doesNotFireLogoutRoute() {
        let (sut, _, _) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        sut.didToggleDarkTheme(true)
        #expect(route == nil)
    }

    // MARK: - didUpdateUserName / didUpdateResidenceCountry mutual independence

    @Test func didUpdateUserName_doesNotCallResidenceUpdate() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didUpdateUserName("New Name")
        #expect(updateUser.residenceCallCount == 0)
    }

    @Test func didUpdateResidenceCountry_callsResidenceUpdateOnce() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didUpdateResidenceCountry("FR")
        #expect(updateUser.residenceCallCount == 1)
        #expect((updateUser.updatedResidenceCountryCode ?? nil) == "FR")
    }

    @Test func didUpdateResidenceCountry_doesNotCallNameUpdate() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didUpdateResidenceCountry("FR")
        #expect(updateUser.callCount == 0)
    }

    @Test func didUpdateResidenceCountry_nil_propagatesNilToUseCase() {
        let (sut, _, updateUser) = makeSUT(user: makeUser(name: "X"))
        sut.viewDidLoad()
        sut.didUpdateResidenceCountry(nil)
        #expect(updateUser.residenceCallCount == 1)
        // outer optional is .some (use case was called), inner optional is .none (nil propagated)
        #expect(updateUser.updatedResidenceCountryCode != nil)
        #expect((updateUser.updatedResidenceCountryCode ?? nil) == nil)
    }

    // MARK: - No side effects on plain viewDidLoad

    @Test func viewDidLoad_userExists_doesNotInvokeUpdateUseCases() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        #expect(updateUser.callCount == 0)
        #expect(updateUser.residenceCallCount == 0)
    }

    @Test func viewDidLoad_noUser_doesNotInvokeUpdateUseCases() {
        let (sut, _, updateUser) = makeSUT(user: nil)
        sut.viewDidLoad()
        #expect(updateUser.callCount == 0)
        #expect(updateUser.residenceCallCount == 0)
    }

    // MARK: - Card content from AuthUser

    @Test func viewDidLoad_userExists_cardCarriesResidenceFromUser() {
        let user = AuthUser(
            id: "id",
            name: "Anna",
            createdAt: Date(),
            residenceCountryCode: "IT",
            isWorldCitizen: false
        )
        let (sut, _, _) = makeSUT(user: user)
        var captured: [ProfileSectionModel] = []
        sut.onSectionsChange = { captured = $0 }
        sut.viewDidLoad()
        // residence is consumed via route .openProfileDetails — verify via tap:
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        sut.didSelectItem(at: IndexPath(row: 0, section: 0))
        guard case .openProfileDetails(_, let code) = route else {
            Issue.record("Expected .openProfileDetails route")
            return
        }
        #expect(code == "IT")
        // sanity: the user's name is the one on the card
        guard case .profileCard(let card) = captured.first?.items.first else {
            Issue.record("Missing profileCard item")
            return
        }
        #expect(card.name == "Anna")
    }
}
