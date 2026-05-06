//
//  L10n.swift
//  Xplora
//
//  Generated-like localization accessors.
//

import Foundation

enum L10n {
    enum Common {
        static let cancel = L10n.tr("Localizable", "common.cancel")
        static let delete = L10n.tr("Localizable", "common.delete")
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
            static let englishNative = L10n.tr("Localizable", "profile.language.native_english")
            static let russianNative = L10n.tr("Localizable", "profile.language.native_russian")
        }

        enum Danger {
            static let footnote = L10n.tr("Localizable", "profile.danger.footnote")
        }

        enum Details {
            static let title = L10n.tr("Localizable", "profile.details.title")
            static let placeholder = L10n.tr("Localizable", "profile.details.placeholder")
        }

        enum LanguageSelection {
            static let title = L10n.tr("Localizable", "profile.language_selection.title")
            static let placeholder = L10n.tr("Localizable", "profile.language_selection.placeholder")
            static let restartMessage = L10n.tr("Localizable", "profile.language_selection.restart_message")
        }

        enum About {
            static let title = L10n.tr("Localizable", "profile.about.title")
            static let placeholder = L10n.tr("Localizable", "profile.about.placeholder")
            static let subtitle = L10n.tr("Localizable", "profile.about.subtitle")
            static let footer = L10n.tr("Localizable", "profile.about.footer")
            static let version = L10n.tr("Localizable", "profile.about.version")
            static let build = L10n.tr("Localizable", "profile.about.build")
            static let developerResourcesTitle = L10n.tr("Localizable", "profile.about.developer_resources_title")
            static let githubRepository = L10n.tr("Localizable", "profile.about.github_repository")
            static let readmeGuide = L10n.tr("Localizable", "profile.about.readme_guide")
            static func versionBuild(_ p1: Any, _ p2: Any) -> String {
                L10n.tr("Localizable", "profile.about.version_build_format", String(describing: p1), String(describing: p2))
            }

            enum Card {
                static let aboutTitle = L10n.tr("Localizable", "profile.about.card.about_title")
                static let aboutText = L10n.tr("Localizable", "profile.about.card.about_text")
                static let featuresTitle = L10n.tr("Localizable", "profile.about.card.features_title")
                static let featuresText = L10n.tr("Localizable", "profile.about.card.features_text")
                static let technologiesTitle = L10n.tr("Localizable", "profile.about.card.technologies_title")
                static let technologiesText = L10n.tr("Localizable", "profile.about.card.technologies_text")
            }
        }

        enum Privacy {
            static let title = L10n.tr("Localizable", "profile.privacy.title")
            static let placeholder = L10n.tr("Localizable", "profile.privacy.placeholder")
            static let fallbackTitle = L10n.tr("Localizable", "profile.privacy.fallback_title")
            static let fallbackMessage = L10n.tr("Localizable", "profile.privacy.fallback_message")
        }

        enum Share {
            static let text = L10n.tr("Localizable", "profile.share.text")
        }

        enum Delete {
            static let confirmationTitle = L10n.tr("Localizable", "profile.delete.confirmation_title")
            static let confirmationMessage = L10n.tr("Localizable", "profile.delete.confirmation_message")
            static let stubTitle = L10n.tr("Localizable", "profile.delete.stub_title")
            static let stubMessage = L10n.tr("Localizable", "profile.delete.stub_message")
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
