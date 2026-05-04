//
//  NotePresentationTitle.swift
//  Xplora
//

import Foundation

enum NotePresentationTitle {
    static func displayTitle(from rawTitle: String?) -> String {
        let trimmedTitle = rawTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedTitle.isEmpty ? L10n.Notes.Presentation.untitled : trimmedTitle
    }
}
