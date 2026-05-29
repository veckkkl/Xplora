//
//  ProfileViewModel.swift
//  Xplora
//

import Foundation

enum ProfileRoute: Equatable {
    case openProfileDetails(status: TravelStatus, residenceCountryCode: String?)
    case openLanguageSelection
    case openAboutXplora
    case openPrivacyPolicy
    case shareApp
    case rateApp
    case confirmDeleteData
    case logout
}

@MainActor
protocol ProfileViewModelInput: AnyObject {
    func viewDidLoad()
    func didSelectItem(at indexPath: IndexPath)
    func didToggleDarkTheme(_ isOn: Bool)
    func didUpdateUserName(_ name: String)
    func didUpdateResidenceCountry(_ residenceCountryCode: String?)
    func didConfirmDeleteData()
}

@MainActor
protocol ProfileViewModelOutput: AnyObject {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)? { get set }
    var onRoute: ((ProfileRoute) -> Void)? { get set }
}

@MainActor
final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)?
    var onRoute: ((ProfileRoute) -> Void)?

    private let getCurrentUser: GetCurrentUserUseCase
    private let updateCurrentUser: UpdateCurrentUserUseCase
    private let getStatistics: GetStatisticsUseCase
    private let getTrips: GetTripsUseCase
    private let travelStatusResolver: TravelStatusResolver

    private var sections: [ProfileSectionModel] = []
    private var isDarkThemeEnabled = AppThemeManager.isDarkThemeEnabled
    private var profileStats = ProfileStatsSnapshot.zero

    init(
        getCurrentUser: GetCurrentUserUseCase,
        updateCurrentUser: UpdateCurrentUserUseCase,
        getStatistics: GetStatisticsUseCase,
        getTrips: GetTripsUseCase,
        travelStatusResolver: TravelStatusResolver = TravelStatusResolver()
    ) {
        self.getCurrentUser = getCurrentUser
        self.updateCurrentUser = updateCurrentUser
        self.getStatistics = getStatistics
        self.getTrips = getTrips
        self.travelStatusResolver = travelStatusResolver
    }

    func viewDidLoad() {
        guard getCurrentUser.execute() != nil else {
            onRoute?(.logout)
            return
        }
        refreshSections()
        loadProfileStats()
    }

    func didSelectItem(at indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section) else { return }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.row) else { return }

        let item = section.items[indexPath.row]
        switch item {
        case .profileCard:
            onRoute?(.openProfileDetails(
                status: currentTravelStatus(),
                residenceCountryCode: getCurrentUser.execute()?.residenceCountryCode
            ))
        case .action(let actionItem):
            switch actionItem.action {
            case .darkTheme:
                didToggleDarkTheme(!isDarkThemeEnabled)
            default:
                onRoute?(route(for: actionItem.action))
            }
        }
    }

    func didToggleDarkTheme(_ isOn: Bool) {
        isDarkThemeEnabled = isOn
        AppThemeManager.apply(isDark: isOn)
        refreshSections()
    }

    func didUpdateUserName(_ name: String) {
        updateCurrentUser.execute(name: name)
        ProfileUserSettings.saveName(name)
        refreshSections()
    }

    func didUpdateResidenceCountry(_ residenceCountryCode: String?) {
        updateCurrentUser.execute(residenceCountryCode: residenceCountryCode)
        refreshSections()
    }

    // Deleting user data routes through the same reset path as logout:
    // AppCoordinator clears the stored AuthUser and returns to onboarding.
    func didConfirmDeleteData() {
        onRoute?(.logout)
    }

    private func buildSections() -> [ProfileSectionModel] {
        let userName = getCurrentUser.execute()?.name ?? ProfileUserSettings.currentName
        return [
            ProfileSectionModel(
                section: .profileCard,
                items: [
                    .profileCard(
                        ProfileCardItem(
                            initials: ProfileUserSettings.initials(from: userName),
                            avatarFileName: ProfileUserSettings.currentAvatarFileName,
                            name: userName,
                            status: currentTravelStatus(),
                            isStatusVisible: ProfileUserSettings.isStatusVisible,
                            stats: makeProfileStats()
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .appearance,
                items: [
                    .action(ProfileActionItem(
                        action: .darkTheme,
                        title: L10n.Profile.Item.darkTheme,
                        value: nil,
                        style: .standard,
                        accessory: .toggle(isDarkThemeEnabled),
                        iconSystemName: "moon.fill",
                        iconTint: .blue
                    )),
                    .action(ProfileActionItem(
                        action: .language,
                        title: L10n.Profile.Item.language,
                        value: currentLanguageDisplayValue(),
                        style: .standard,
                        accessory: .disclosure,
                        iconSystemName: "globe",
                        iconTint: .green
                    ))
                ]
            ),
            ProfileSectionModel(
                section: .app,
                items: [
                    .action(ProfileActionItem(
                        action: .shareWithFriends,
                        title: L10n.Profile.Item.share,
                        value: nil,
                        style: .standard,
                        accessory: .none,
                        iconSystemName: "square.and.arrow.up",
                        iconTint: .blue
                    )),
                    .action(ProfileActionItem(
                        action: .rateApp,
                        title: L10n.Profile.Item.rateApp,
                        value: nil,
                        style: .standard,
                        accessory: .none,
                        iconSystemName: "star.fill",
                        iconTint: .yellow
                    )),
                    .action(ProfileActionItem(
                        action: .about,
                        title: L10n.Profile.Item.aboutXplora,
                        value: nil,
                        style: .standard,
                        accessory: .disclosure,
                        iconSystemName: "info.circle",
                        iconTint: .blue
                    )),
                    .action(ProfileActionItem(
                        action: .privacyPolicy,
                        title: L10n.Profile.Item.privacyPolicy,
                        value: nil,
                        style: .standard,
                        accessory: .disclosure,
                        iconSystemName: "lock.shield",
                        iconTint: .gray
                    ))
                ]
            ),
            ProfileSectionModel(
                section: .data,
                items: [
                    .action(ProfileActionItem(
                        action: .deleteData,
                        title: L10n.Profile.Item.deleteData,
                        value: nil,
                        style: .destructive,
                        accessory: .none,
                        iconSystemName: "trash",
                        iconTint: .red
                    ))
                ]
            )
        ]
    }

    private func currentLanguageDisplayValue() -> String {
        AppLanguage.current.displayName
    }

    private func currentTravelStatus() -> TravelStatus {
        travelStatusResolver.resolve(
            countriesCount: profileStats.countriesCount,
            tripsCount: profileStats.tripsCount,
            worldProgressPercent: Double(profileStats.worldProgressPercent)
        )
    }

    private func makeProfileStats() -> [ProfileCardItem.Stat] {
        [
            .init(
                iconSystemName: "percent",
                value: "\(profileStats.worldProgressPercent)",
                label: L10n.Profile.Card.Stat.ofWorld,
                tint: .blue
            ),
            .init(
                iconSystemName: "flag.fill",
                value: "\(profileStats.countriesCount)",
                label: L10n.Profile.Card.Stat.countries,
                tint: .green
            ),
            .init(
                iconSystemName: "globe.europe.africa.fill",
                value: "\(profileStats.tripsCount)",
                label: L10n.Profile.Card.Stat.trips,
                tint: .purple
            )
        ]
    }

    private func loadProfileStats() {
        Task { [weak self] in
            guard let self else { return }
            async let summaryTask = self.getStatistics.execute()
            async let tripsTask = self.getTrips.execute()
            do {
                let (summary, trips) = try await (summaryTask, tripsTask)
                self.profileStats = ProfileStatsSnapshot(
                    worldProgressPercent: summary.worldProgressPercent,
                    countriesCount: summary.visitedUNCount,
                    tripsCount: trips.count
                )
                self.refreshSections()
            } catch {
                self.profileStats = .zero
                self.refreshSections()
            }
        }
    }

    private func route(for action: ProfileItemAction) -> ProfileRoute {
        switch action {
        case .darkTheme:
            preconditionFailure("Handled before route(for:) is called.")
        case .language:       return .openLanguageSelection
        case .rateApp:        return .rateApp
        case .about:          return .openAboutXplora
        case .privacyPolicy:  return .openPrivacyPolicy
        case .shareWithFriends: return .shareApp
        case .deleteData:     return .confirmDeleteData
        }
    }

    private func refreshSections() {
        let newSections = buildSections()
        guard newSections != sections else { return }
        sections = newSections
        onSectionsChange?(sections)
    }
}
