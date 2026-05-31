//
//  ProfileViewModelSectionsTests.swift
//  XploraTests
//

import Testing
import Foundation
@testable import Xplora

@MainActor
struct ProfileViewModelSectionsTests {

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

    private func sections(after action: (ProfileViewModel) -> Void, user: AuthUser? = nil) -> [ProfileSectionModel] {
        let (sut, _, _) = makeSUT(user: user ?? makeUser())
        var captured: [ProfileSectionModel] = []
        sut.onSectionsChange = { captured = $0 }
        sut.viewDidLoad()
        action(sut)
        return captured
    }

    // MARK: - Section order and composition

    @Test func viewDidLoad_buildsAllFourSectionsInExpectedOrder() {
        let sections = sections(after: { _ in })
        let kinds = sections.map { $0.section }
        #expect(kinds == [.profileCard, .appearance, .app, .data])
    }

    @Test func profileCardSection_containsSingleProfileCardItem() {
        let sections = sections(after: { _ in })
        let profileCardSection = sections.first(where: { $0.section == .profileCard })
        #expect(profileCardSection?.items.count == 1)
        guard case .profileCard = profileCardSection?.items.first else {
            Issue.record("Expected first item to be .profileCard")
            return
        }
    }

    @Test func appearanceSection_containsDarkThemeAndLanguageActions() {
        let sections = sections(after: { _ in })
        guard let appearance = sections.first(where: { $0.section == .appearance }) else {
            Issue.record("Missing appearance section")
            return
        }
        let actions = appearance.items.compactMap { item -> ProfileItemAction? in
            if case .action(let a) = item { return a.action }
            return nil
        }
        #expect(actions == [.darkTheme, .language])
    }

    @Test func appSection_containsAllExpectedActionsInOrder() {
        let sections = sections(after: { _ in })
        guard let appSection = sections.first(where: { $0.section == .app }) else {
            Issue.record("Missing app section")
            return
        }
        let actions = appSection.items.compactMap { item -> ProfileItemAction? in
            if case .action(let a) = item { return a.action }
            return nil
        }
        #expect(actions == [.shareWithFriends, .rateApp, .about, .privacyPolicy])
    }

    @Test func dataSection_containsSingleDeleteDataAction() {
        let sections = sections(after: { _ in })
        guard let dataSection = sections.first(where: { $0.section == .data }) else {
            Issue.record("Missing data section")
            return
        }
        let actions = dataSection.items.compactMap { item -> ProfileItemAction? in
            if case .action(let a) = item { return a.action }
            return nil
        }
        #expect(actions == [.deleteData])
    }

    // MARK: - Card content reflects current user

    @Test func profileCard_initialStatus_isAdventureTravelerForZeroStats() {
        let sections = sections(after: { _ in })
        guard case .profileCard(let card) = sections.first?.items.first else {
            Issue.record("Missing profileCard item")
            return
        }
        #expect(card.status == .adventureTraveler)
    }

    @Test func profileCard_containsThreeStats() {
        let sections = sections(after: { _ in })
        guard case .profileCard(let card) = sections.first?.items.first else {
            Issue.record("Missing profileCard item")
            return
        }
        #expect(card.stats.count == 3)
    }

    @Test func profileCard_initials_derivedFromUserName() {
        let sections = sections(after: { _ in }, user: makeUser(name: "Anna Maria"))
        guard case .profileCard(let card) = sections.first?.items.first else {
            Issue.record("Missing profileCard item")
            return
        }
        #expect(card.initials == "AM")
    }

    // MARK: - Refresh after mutations

    @Test func didUpdateResidenceCountry_doesNotEmitSectionsWhenCardDataUnchanged() {
        // The profile card does not display the residence country (residence is consumed
        // only by the .openProfileDetails route), so a country update keeps the rendered
        // sections deep-equal to the previous snapshot and onSectionsChange is suppressed.
        let (sut, getUser, _) = makeSUT(user: makeUser(residenceCountryCode: nil))
        sut.viewDidLoad()

        getUser.stubbedUser = makeUser(residenceCountryCode: "FR")
        var refreshCount = 0
        sut.onSectionsChange = { _ in refreshCount += 1 }
        sut.didUpdateResidenceCountry("FR")
        #expect(refreshCount == 0)
    }

    @Test func didToggleDarkTheme_changingValue_emitsSectionsRefresh() {
        let (sut, _, _) = makeSUT(user: makeUser())
        sut.viewDidLoad()
        var captured: [ProfileSectionModel] = []
        sut.onSectionsChange = { captured = $0 }
        // Flip whichever current value is to a guaranteed-different one
        sut.didToggleDarkTheme(true)
        sut.didToggleDarkTheme(false)
        #expect(captured.isEmpty == false)
    }

    @Test func didUpdateUserName_changingValue_emitsRefreshWithNewName() {
        let (sut, getUser, _) = makeSUT(user: makeUser(name: "Old Name"))
        sut.viewDidLoad()

        getUser.stubbedUser = makeUser(name: "Fresh Name")
        var captured: [ProfileSectionModel] = []
        sut.onSectionsChange = { captured = $0 }
        sut.didUpdateUserName("Fresh Name")
        guard case .profileCard(let card) = captured.first?.items.first else {
            Issue.record("Missing profileCard item after rename")
            return
        }
        #expect(card.name == "Fresh Name")
    }

    @Test func didUpdateUserName_sameName_doesNotEmitSectionsRefresh() {
        let (sut, _, _) = makeSUT(user: makeUser(name: "Same"))
        sut.viewDidLoad()

        var refreshCount = 0
        sut.onSectionsChange = { _ in refreshCount += 1 }
        // Same name → buildSections() result equals current sections → no emission.
        sut.didUpdateUserName("Same")
        #expect(refreshCount == 0)
    }
}
