//
//  NoteDateRangeFormatter.swift
//  Xplora
//

import Foundation

enum NoteDateRangeFormatter {
    static func displayText(for date: Date) -> String {
        singleDateFormatter.string(from: date)
    }

    static func displayText(startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return singleDateFormatter.string(from: startDate)
        }

        return "\(singleDateFormatter.string(from: startDate)) – \(singleDateFormatter.string(from: endDate))"
    }

    private static let singleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
