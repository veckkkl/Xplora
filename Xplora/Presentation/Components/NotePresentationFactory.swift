//
//  NotePresentationFactory.swift
//  Xplora
//

import Foundation

enum NotePresentationFactory {
    static func title(for note: Note) -> String {
        if let title = note.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }

        let placeName = note.location?.placeName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !placeName.isEmpty {
            return placeName
        }

        return L10n.Notes.Presentation.untitled
    }

    static func textPreview(for note: Note) -> String {
        let trimmed = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let collapsedWhitespace = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsedWhitespace
    }

    static func formattedDateRange(for note: Note) -> String {
        let resolvedRange = NoteDateRangeResolver.effectiveRange(
            tripStartDate: note.tripStartDate,
            tripEndDate: note.tripEndDate
        )
        if let start = resolvedRange.start, let end = resolvedRange.end {
            return NoteDateRangeFormatter.displayText(startDate: start, endDate: end)
        }
        return NoteDateRangeFormatter.displayText(for: note.createdAt)
    }

    static func locationTitle(for note: Note) -> String? {
        let trimmed = note.location?.placeName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    static func locationSubtitle(for note: Note) -> String? {
        guard let address = note.location?.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty else {
            return nil
        }
        return address
    }

    static func locationChipText(for note: Note) -> String? {
        if let title = locationTitle(for: note) {
            return title
        }

        if let subtitle = locationSubtitle(for: note) {
            return subtitle
        }

        return nil
    }

    static func previewOverflowCount(photoCount: Int) -> Int {
        guard photoCount >= 10 else { return 0 }
        return photoCount - 5
    }
}
