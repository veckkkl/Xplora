//
//  ProfileModels.swift
//  Xplora
//

import Foundation

enum ProfileSection: Int, CaseIterable {
    case profileCard
    case appearance
    case app
    case data

    var headerTitle: String? {
        switch self {
        case .profileCard:
            return L10n.Profile.title
        case .appearance:
            return L10n.Profile.Section.appearance
        case .app:
            return L10n.Profile.Section.app
        case .data:
            return L10n.Profile.Section.data
        }
    }
}

enum ProfileItemAction: Equatable {
    case darkTheme
    case language
    case rateApp
    case about
    case privacyPolicy
    case shareWithFriends
    case deleteData
}

enum ProfileRowAccessory: Equatable {
    case none
    case disclosure
    case toggle(Bool)
}

enum ProfileRowStyle: Equatable {
    case standard
    case destructive
}

enum ProfileIconTint: Equatable {
    case blue
    case green
    case yellow
    case purple
    case gray
    case red
}

enum ProfileStatus: Equatable {
    case worldExplorer
    case placeCollector
    case adventureTraveler

    var title: String {
        switch self {
        case .worldExplorer:
            return L10n.Profile.Card.Status.worldExplorer
        case .placeCollector:
            return L10n.Profile.Card.Status.placeCollector
        case .adventureTraveler:
            return L10n.Profile.Card.Status.adventureTraveler
        }
    }
}

struct ProfileCardItem: Equatable {
    struct Stat: Equatable {
        let iconSystemName: String
        let value: String
        let label: String
        let tint: ProfileIconTint
    }

    let initials: String
    let name: String
    let status: ProfileStatus
    let stats: [Stat]
}

struct ProfileActionItem: Equatable {
    let action: ProfileItemAction
    let title: String
    let value: String?
    let style: ProfileRowStyle
    let accessory: ProfileRowAccessory
    let iconSystemName: String?
    let iconTint: ProfileIconTint
}

enum ProfileSectionItem: Equatable {
    case profileCard(ProfileCardItem)
    case action(ProfileActionItem)
}

struct ProfileSectionModel: Equatable {
    let section: ProfileSection
    let items: [ProfileSectionItem]
}
