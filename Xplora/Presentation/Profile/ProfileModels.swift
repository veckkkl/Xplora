//
//  ProfileModels.swift
//  Xplora
//

import Foundation

enum ProfileSection: Int, CaseIterable {
    case profileCard
    case appSettings
    case support
    case dangerZone

    var headerTitle: String? {
        switch self {
        case .profileCard:
            return nil
        case .appSettings:
            return L10n.Profile.Section.appSettings
        case .support:
            return L10n.Profile.Section.support
        case .dangerZone:
            return L10n.Profile.Section.dangerZone
        }
    }
}

enum ProfileItemAction: Equatable {
    case language
    case about
    case privacyPolicy
    case shareWithFriends
    case deleteData
}

enum ProfileRowAccessory: Equatable {
    case none
    case disclosure
}

enum ProfileRowStyle: Equatable {
    case standard
    case destructive
}

struct ProfileCardItem: Equatable {
    let initials: String
    let name: String
    let subtitle: String
}

struct ProfileActionItem: Equatable {
    let action: ProfileItemAction
    let title: String
    let value: String?
    let style: ProfileRowStyle
    let accessory: ProfileRowAccessory
    let iconSystemName: String?
}

enum ProfileSectionItem: Equatable {
    case profileCard(ProfileCardItem)
    case action(ProfileActionItem)
}

struct ProfileSectionModel: Equatable {
    let section: ProfileSection
    let items: [ProfileSectionItem]
}
