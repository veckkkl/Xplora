//
//  NoteDateRangeNormalizer.swift
//  Xplora
//

import Foundation

enum NoteDateRangeNormalizer {
    static func today(calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.startOfDay(for: Date())
    }

    static func normalizedRange(
        start: Date?,
        end: Date?,
        calendar: Calendar = .autoupdatingCurrent,
        today: Date = NoteDateRangeNormalizer.today()
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
}

enum NoteDateRangeResolver {
    static func effectiveRange(
        tripStartDate: Date?,
        tripEndDate: Date?
    ) -> (start: Date?, end: Date?) {
        NoteDateRangeNormalizer.normalizedRange(
            start: tripStartDate,
            end: tripEndDate
        )
    }
}
