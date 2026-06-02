//
//  TripNotesCountProvider.swift
//  Xplora
//

import Foundation

/// Counts and filters notes that belong to a given trip based on the trip's
/// country (ISO 3166-1 alpha-2 placeCode) and date range.
///
/// A note belongs to a trip when:
/// - it has a `location`,
/// - `location.countryCode` is set,
/// - `countryCode` equals `trip.placeCode` (case-insensitive),
/// - the note's effective date falls within the trip's inclusive day range.
///
/// Legacy notes without `countryCode` are intentionally excluded — see the
/// step-2 migration design doc. The Timeline cell count and the Notes
/// screen filter both call into this single source of truth, so the two
/// views can never disagree about what "belongs to a trip" means.
protocol TripNotesCountProviding {
    /// Returns the subset of `notes` that match the trip.
    func notes(for trip: Trip, in notes: [Note]) -> [Note]
    /// Convenience count built on top of `notes(for:in:)`.
    func notesCount(for trip: Trip, notes: [Note]) -> Int
}

extension TripNotesCountProviding {
    func notesCount(for trip: Trip, notes: [Note]) -> Int {
        self.notes(for: trip, in: notes).count
    }
}

final class NoteLocationTripNotesCountProvider: TripNotesCountProviding {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func notes(for trip: Trip, in notes: [Note]) -> [Note] {
        let tripCode = trip.placeCode.uppercased()
        let dayWindow = inclusiveDayRange(start: trip.startDate, end: trip.endDate)

        return notes.filter { note in
            guard let location = note.location,
                  let countryCode = location.countryCode,
                  countryCode.uppercased() == tripCode else {
                return false
            }
            let noteDate = Self.effectiveDate(of: note)
            return noteDate >= dayWindow.start && noteDate < dayWindow.endExclusive
        }
    }

    // Trip dates are entered as calendar days; their time-of-day is unspecified.
    // Snap [start, end] to a half-open [startOfDay(start), startOfDay(end + 1d))
    // so a note created at 23:50 on the last trip day still falls inside.
    private func inclusiveDayRange(start: Date, end: Date) -> (start: Date, endExclusive: Date) {
        let startOfDay = calendar.startOfDay(for: start)
        let endStartOfDay = calendar.startOfDay(for: end)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endStartOfDay) ?? end
        return (startOfDay, endExclusive)
    }

    // tripStartDate is what the user marks as "when this happened in real life";
    // createdAt is the technical fallback when the user didn't set a date.
    private static func effectiveDate(of note: Note) -> Date {
        note.tripStartDate ?? note.createdAt
    }
}
