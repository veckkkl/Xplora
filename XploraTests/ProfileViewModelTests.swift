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
        let sut = ProfileViewModel(getCurrentUser: getUser, updateCurrentUser: updateUser)
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

    // MARK: - Logout

    @Test func selectLogoutItem_firesLogoutRoute() {
        let (sut, _, _) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        var route: ProfileRoute?
        sut.onRoute = { route = $0 }
        // Data section is index 3, logout row is index 0
        sut.didSelectItem(at: IndexPath(row: 0, section: 3))
        #expect(route == .logout)
    }

    @Test func selectLogoutItem_doesNotCallUpdateUseCase() {
        let (sut, _, updateUser) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        sut.didSelectItem(at: IndexPath(row: 0, section: 3))
        #expect(updateUser.callCount == 0)
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
}
