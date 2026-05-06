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
    case confirmDeleteData
}

@MainActor
protocol ProfileViewModelInput: AnyObject {
    func viewDidLoad()
    func didSelectItem(at indexPath: IndexPath)
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

    private var sections: [ProfileSectionModel] = []

    func viewDidLoad() {
        sections = buildSections()
        onSectionsChange?(sections)
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
            onRoute?(route(for: actionItem.action))
        }
    }

    private func buildSections() -> [ProfileSectionModel] {
        [
            ProfileSectionModel(
                section: .profileCard,
                items: [
                    .profileCard(
                        ProfileCardItem(
                            initials: "VB",
                            name: "valentina balde",
                            subtitle: L10n.Profile.Card.subtitle
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .appSettings,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .language,
                            title: L10n.Profile.Item.language,
                            value: currentLanguageDisplayValue(),
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "globe"
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .support,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .about,
                            title: L10n.Profile.Item.aboutXplora,
                            value: nil,
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "info.circle"
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .privacyPolicy,
                            title: L10n.Profile.Item.privacyPolicy,
                            value: nil,
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "lock.shield"
                        )
                    ),
                    .action(
                        ProfileActionItem(
                            action: .shareWithFriends,
                            title: L10n.Profile.Item.shareWithFriends,
                            value: nil,
                            style: .standard,
                            accessory: .disclosure,
                            iconSystemName: "square.and.arrow.up"
                        )
                    )
                ]
            ),
            ProfileSectionModel(
                section: .dangerZone,
                items: [
                    .action(
                        ProfileActionItem(
                            action: .deleteData,
                            title: L10n.Profile.Item.deleteData,
                            value: nil,
                            style: .destructive,
                            accessory: .none,
                            iconSystemName: "trash"
                        )
                    )
                ]
            )
        ]
    }

    private func currentLanguageDisplayValue() -> String {
        AppLanguage.current.displayName
    }

    private func route(for action: ProfileItemAction) -> ProfileRoute {
        switch action {
        case .language:
            return .openLanguageSelection
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
}
