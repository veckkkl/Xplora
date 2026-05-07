//
//  ProfileViewModel.swift
//  Xplora
//

import Foundation

enum ProfileRoute {
    case openProfileDetails
    case openLanguageSelection
    case openAboutXplora
    case openPrivacyPolicy
    case shareApp
    case rateApp
    case confirmDeleteData
}

@MainActor
protocol ProfileViewModelInput: AnyObject {
    func viewDidLoad()
    func didSelectItem(at indexPath: IndexPath)
    func didToggleDarkTheme(_ isOn: Bool)
}

@MainActor
protocol ProfileViewModelOutput: AnyObject {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)? { get set }
    var onRoute: ((ProfileRoute) -> Void)? { get set }
}

@MainActor
final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    private enum Constants {
        static let darkThemeEnabledKey = "profile.dark_theme_enabled"
    }

    var onSectionsChange: (([ProfileSectionModel]) -> Void)?
    var onRoute: ((ProfileRoute) -> Void)?

    private var sections: [ProfileSectionModel] = []
    private var isDarkThemeEnabled = UserDefaults.standard.bool(forKey: Constants.darkThemeEnabledKey)

    func viewDidLoad() {
        refreshSections()
    }

    func didSelectItem(at indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section) else { return }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.row) else { return }

        let item = section.items[indexPath.row]
        switch item {
        case .profileCard:
            onRoute?(.openProfileDetails)
        case .action(let actionItem):
            guard actionItem.action != .darkTheme else {
                didToggleDarkTheme(!isDarkThemeEnabled)
                return
            }
            onRoute?(route(for: actionItem.action))
        }
    }

    func didToggleDarkTheme(_ isOn: Bool) {
        isDarkThemeEnabled = isOn
        UserDefaults.standard.set(isOn, forKey: Constants.darkThemeEnabledKey)
        refreshSections()
    }

    private func buildSections() -> [ProfileSectionModel] {
        [
            ProfileSectionModel(
                section: .profileCard,
                items: [
                    .profileCard(
                        ProfileCardItem(
                            initials: ProfileUserSettings.initials(from: ProfileUserSettings.currentName),
                            avatarFileName: ProfileUserSettings.currentAvatarFileName,
                            name: ProfileUserSettings.currentName,
                            status: ProfileUserSettings.currentStatus,
                            isStatusVisible: ProfileUserSettings.isStatusVisible,
                            stats: makeProfileStats()
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .appearance,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .darkTheme,
                            title: L10n.Profile.Item.darkTheme,
                            value: nil,
                            style: .standard,
                            accessory: .toggle(isDarkThemeEnabled),
                            iconSystemName: "moon.fill",
                            iconTint: .blue
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .language,
                            title: L10n.Profile.Item.language,
                            value: currentLanguageDisplayValue(),
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "globe",
                            iconTint: .green
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .app,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .shareWithFriends,
                            title: L10n.Profile.Item.share,
                            value: nil,
                            style: .standard,
                            accessory: .none,
                            iconSystemName: "square.and.arrow.up",
                            iconTint: .blue
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .rateApp,
                            title: L10n.Profile.Item.rateApp,
                            value: nil,
                            style: .standard,
                            accessory: .none,
                            iconSystemName: "star.fill",
                            iconTint: .yellow
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .about,
                            title: L10n.Profile.Item.aboutXplora,
                            value: nil,
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "info.circle",
                            iconTint: .blue
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .privacyPolicy,
                            title: L10n.Profile.Item.privacyPolicy,
                            value: nil,
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "lock.shield",
                            iconTint: .gray
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .data,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .deleteData,
                            title: L10n.Profile.Item.deleteData,
                            value: nil,
                            style: .destructive,
                            accessory: .none,
                            iconSystemName: "trash",
                            iconTint: .red
                        )
                    )
                ]
            )
        ]
    }

    private func currentLanguageDisplayValue() -> String {
        AppLanguage.current.displayName
    }

    private func makeProfileStats() -> [ProfileCardItem.Stat] {
        [
            .init(
                iconSystemName: "location.fill",
                value: "23",
                label: L10n.Profile.Card.Stat.places,
                tint: .blue
            ),
            .init(
                iconSystemName: "flag.fill",
                value: "7",
                label: L10n.Profile.Card.Stat.countries,
                tint: .green
            ),
            .init(
                iconSystemName: "globe.europe.africa.fill",
                value: "12",
                label: L10n.Profile.Card.Stat.trips,
                tint: .purple
            )
        ]
    }

    private func route(for action: ProfileItemAction) -> ProfileRoute {
        switch action {
        case .darkTheme:
            preconditionFailure("Dark theme action is handled directly via toggle.")
        case .language:
            return .openLanguageSelection
        case .rateApp:
            return .rateApp
        case .about:
            return .openAboutXplora
        case .privacyPolicy:
            return .openPrivacyPolicy
        case .shareWithFriends:
            return .shareApp
        case .deleteData:
            return .confirmDeleteData
        }
    }

    private func refreshSections() {
        sections = buildSections()
        onSectionsChange?(sections)
    }
}
