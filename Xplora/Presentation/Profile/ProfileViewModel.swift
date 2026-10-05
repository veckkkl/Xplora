//
//  ProfileViewModel.swift
//  Xplora
//

import Foundation

enum ProfileRoute: Equatable {
    case openProfileDetails(status: TravelStatus, residenceCountryCode: String?)
    case openThemeSelection(current: AppTheme)
    case openAppLanguageSettings
    case openAboutXplora
    case openPrivacyPolicy
    case shareApp
    case rateApp
    case confirmDeleteData
    case logout
    /// All local data was deleted; the app should start over.
    case allDataDeleted
}

@MainActor
protocol ProfileViewModelInput: AnyObject {
    func viewDidLoad()
    func didSelectItem(at indexPath: IndexPath)
    func didSelectTheme(_ theme: AppTheme)
    /// Returns `false` when the name wasn't saved.
    @discardableResult func didUpdateUserName(_ name: String) -> Bool
    /// Returns `false` when the country wasn't saved.
    @discardableResult func didUpdateResidenceCountry(_ residenceCountryCode: String?) -> Bool
    func didConfirmDeleteAllData()
}

@MainActor
protocol ProfileViewModelOutput: AnyObject {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)? { get set }
    var onRoute: ((ProfileRoute) -> Void)? { get set }
    var onDeleteAllDataInProgress: ((Bool) -> Void)? { get set }
    var onDeleteAllDataFailed: ((String) -> Void)? { get set }
}

@MainActor
final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)?
    var onRoute: ((ProfileRoute) -> Void)?
    var onDeleteAllDataInProgress: ((Bool) -> Void)?
    var onDeleteAllDataFailed: ((String) -> Void)?

    private let getCurrentUser: GetCurrentUserUseCase
    private let updateCurrentUser: UpdateCurrentUserUseCase
    private let getStatistics: GetStatisticsUseCase
    private let getTrips: GetTripsUseCase
    private let deleteAllUserData: DeleteAllUserDataUseCase
    private let travelStatusResolver: TravelStatusResolver
    private let themeManager: AppThemeManaging

    private var sections: [ProfileSectionModel] = []
    private var profileStats = ProfileStatsSnapshot.zero

    init(
        getCurrentUser: GetCurrentUserUseCase,
        updateCurrentUser: UpdateCurrentUserUseCase,
        getStatistics: GetStatisticsUseCase,
        getTrips: GetTripsUseCase,
        deleteAllUserData: DeleteAllUserDataUseCase,
        travelStatusResolver: TravelStatusResolver = TravelStatusResolver(),
        themeManager: AppThemeManaging = AppThemeManager()
    ) {
        self.getCurrentUser = getCurrentUser
        self.updateCurrentUser = updateCurrentUser
        self.getStatistics = getStatistics
        self.getTrips = getTrips
        self.deleteAllUserData = deleteAllUserData
        self.travelStatusResolver = travelStatusResolver
        self.themeManager = themeManager
    }

    func viewDidLoad() {
        // Only a confirmed missing user means logged out. A read error must not
        // trigger logout, which would remove the stored record.
        if case .success(.none) = Result(catching: { try getCurrentUser.execute() }) {
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
                residenceCountryCode: (try? getCurrentUser.execute())?.residenceCountryCode
            ))
        case .action(let actionItem):
            onRoute?(route(for: actionItem.action))
        }
    }

    func didSelectTheme(_ theme: AppTheme) {
        themeManager.apply(theme)
        refreshSections()
    }

    @discardableResult
    func didUpdateUserName(_ name: String) -> Bool {
        defer { refreshSections() }
        do {
            try updateCurrentUser.execute(name: name)
            ProfileUserSettings.saveName(name)
            return true
        } catch {
            // Keep the previous name everywhere; the failure is logged by storage.
            return false
        }
    }

    @discardableResult
    func didUpdateResidenceCountry(_ residenceCountryCode: String?) -> Bool {
        defer { refreshSections() }
        do {
            try updateCurrentUser.execute(residenceCountryCode: residenceCountryCode)
            return true
        } catch {
            return false
        }
    }

    func didConfirmDeleteAllData() {
        Task { await deleteAllData() }
    }

    func deleteAllData() async {
        onDeleteAllDataInProgress?(true)
        do {
            try await deleteAllUserData.execute()
            onDeleteAllDataInProgress?(false)
            onRoute?(.allDataDeleted)
        } catch {
            // Never report success after a partial failure; the use case logs details.
            onDeleteAllDataInProgress?(false)
            onDeleteAllDataFailed?(L10n.Profile.Delete.errorMessage)
        }
    }

    private func buildSections() -> [ProfileSectionModel] {
        let userName = (try? getCurrentUser.execute())?.name ?? ProfileUserSettings.currentName
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
                        action: .theme,
                        title: L10n.Profile.Item.theme,
                        value: themeManager.currentTheme.title,
                        style: .standard,
                        accessory: .disclosure,
                        iconSystemName: "circle.lefthalf.filled",
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
        case .theme:          return .openThemeSelection(current: themeManager.currentTheme)
        case .language:       return .openAppLanguageSettings
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
