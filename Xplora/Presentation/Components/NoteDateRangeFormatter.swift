//
//  NoteDateRangeFormatter.swift
//  Xplora
//

import Foundation

enum NoteDateRangeFormatter {
    static func today(calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.startOfDay(for: Date())
    }

    static func normalizedRange(
        start: Date?,
        end: Date?,
        calendar: Calendar = .autoupdatingCurrent,
        today: Date = NoteDateRangeFormatter.today()
    ) -> (start: Date?, end: Date?) {
        var normalizedStart = start.map { calendar.startOfDay(for: $0) }
        var normalizedEnd = end.map { calendar.startOfDay(for: $0) }
        let normalizedToday = calendar.startOfDay(for: today)

        if let start = normalizedStart, start > normalizedToday {
            normalizedStart = normalizedToday
        }
        if let end = normalizedEnd, end > normalizedToday {
            normalizedEnd = normalizedToday
        }

        if normalizedStart == nil, let normalizedEnd {
            normalizedStart = normalizedEnd
        }
        if normalizedEnd == nil, let normalizedStart {
            normalizedEnd = normalizedStart
        }

        if let start = normalizedStart, let end = normalizedEnd, end < start {
            normalizedEnd = start
        }

        return (normalizedStart, normalizedEnd)
    }

    static func displayText(
        tripStartDate: Date?,
        tripEndDate: Date?,
        createdAt: Date,
        legacyDateRangeText: String?
    ) -> String {
        let normalized = normalizedRange(start: tripStartDate, end: tripEndDate)
        if let start = normalized.start, let end = normalized.end {
            return displayText(startDate: start, endDate: end)
        }

        if let legacyRange = parseLegacyRangeText(legacyDateRangeText) {
            return displayText(startDate: legacyRange.start, endDate: legacyRange.end)
        }

        return singleDateFormatter.string(from: createdAt)
    }

    static func displayText(startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return singleDateFormatter.string(from: startDate)
        }

        return "\(singleDateFormatter.string(from: startDate)) – \(singleDateFormatter.string(from: endDate))"
    }

    static func parseLegacyRangeText(_ text: String?) -> (start: Date, end: Date)? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }

        let separators = [" – ", " - ", "–", "-"]

        for separator in separators {
            let components = text
                .components(separatedBy: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if components.count == 2,
               let start = parseLegacyDate(components[0]),
               let end = parseLegacyDate(components[1]) {
                let normalized = normalizedRange(start: start, end: end)
                if let normalizedStart = normalized.start, let normalizedEnd = normalized.end {
                    return (normalizedStart, normalizedEnd)
                }
            }
        }

        if let singleDate = parseLegacyDate(text) {
            let normalized = normalizedRange(start: singleDate, end: singleDate)
            if let normalizedStart = normalized.start, let normalizedEnd = normalized.end {
                return (normalizedStart, normalizedEnd)
            }
        }

        return nil
    }

    private static func parseLegacyDate(_ value: String) -> Date? {
        if let date = legacyDateFormatter.date(from: value) {
            return Calendar.autoupdatingCurrent.startOfDay(for: date)
        }

        return nil
    }

    private static let singleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let legacyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
}
