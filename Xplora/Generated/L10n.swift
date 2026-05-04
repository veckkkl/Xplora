//
//  L10n.swift
//  Xplora
//
//  Generated-like localization accessors.
//

import Foundation

enum L10n {
    enum Common {
        static let ok = L10n.tr("Localizable", "common.ok")
    }

    enum Profile {
        static let tabTitle = L10n.tr("Localizable", "profile.tab.title")
        static let title = L10n.tr("Localizable", "profile.title")

        enum Card {
            static let subtitle = L10n.tr("Localizable", "profile.card.subtitle")
        }

        enum Section {
            static let appSettings = L10n.tr("Localizable", "profile.section.app_settings")
            static let support = L10n.tr("Localizable", "profile.section.support")
            static let dangerZone = L10n.tr("Localizable", "profile.section.danger_zone")
        }

        enum Item {
            static let language = L10n.tr("Localizable", "profile.item.language")
            static let aboutXplora = L10n.tr("Localizable", "profile.item.about_xplora")
            static let privacyPolicy = L10n.tr("Localizable", "profile.item.privacy_policy")
            static let shareWithFriends = L10n.tr("Localizable", "profile.item.share_with_friends")
            static let deleteData = L10n.tr("Localizable", "profile.item.delete_data")
        }

        enum Language {
            static let english = L10n.tr("Localizable", "profile.language.english")
            static let russian = L10n.tr("Localizable", "profile.language.russian")
        }

        enum Danger {
            static let footnote = L10n.tr("Localizable", "profile.danger.footnote")
        }

        enum Stub {
            static let title = L10n.tr("Localizable", "profile.stub.title")
            static let profileCard = L10n.tr("Localizable", "profile.stub.profile_card")
            static let language = L10n.tr("Localizable", "profile.stub.language")
            static let about = L10n.tr("Localizable", "profile.stub.about")
            static let privacyPolicy = L10n.tr("Localizable", "profile.stub.privacy_policy")
            static let shareWithFriends = L10n.tr("Localizable", "profile.stub.share_with_friends")
            static let deleteData = L10n.tr("Localizable", "profile.stub.delete_data")
        }
    }
}

private extension L10n {
    static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

private final class BundleToken {
    static let bundle = Bundle.main
}
