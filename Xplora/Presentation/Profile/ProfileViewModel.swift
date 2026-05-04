//
//  ProfileViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol ProfileViewModelInput: AnyObject {
    func viewDidLoad()
    func didSelectItem(at indexPath: IndexPath)
}

@MainActor
protocol ProfileViewModelOutput: AnyObject {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)? { get set }
    var onStubAction: ((String) -> Void)? { get set }
}

@MainActor
final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    var onSectionsChange: (([ProfileSectionModel]) -> Void)?
    var onStubAction: ((String) -> Void)?

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
            onStubAction?(L10n.Profile.Stub.profileCard)
        case .action(let actionItem):
            onStubAction?(stubMessage(for: actionItem.action))
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
        let languageCode = Bundle.main.preferredLocalizations.first ?? Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode.hasPrefix("ru") ? L10n.Profile.Language.russian : L10n.Profile.Language.english
    }

    private func stubMessage(for action: ProfileItemAction) -> String {
        switch action {
        case .language:
            return L10n.Profile.Stub.language
        case .about:
            return L10n.Profile.Stub.about
        case .privacyPolicy:
            return L10n.Profile.Stub.privacyPolicy
        case .shareWithFriends:
            return L10n.Profile.Stub.shareWithFriends
        case .deleteData:
            return L10n.Profile.Stub.deleteData
        }
    }
}
