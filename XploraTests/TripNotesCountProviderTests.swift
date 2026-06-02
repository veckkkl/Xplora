//
//  TripNotesCountProviderTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct TripNotesCountProviderTests {
    private let provider = NoteLocationTripNotesCountProvider(calendar: Self.calendar)

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test func ignoresNoteWithoutLocation() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let note = makeNote(countryCode: nil, location: nil, day: 5)
        #expect(provider.notesCount(for: trip, notes: [note]) == 0)
    }

    @Test func ignoresNoteWithoutCountryCode() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let note = makeNote(countryCode: nil, day: 5)
        #expect(provider.notesCount(for: trip, notes: [note]) == 0)
    }

    @Test func ignoresNoteFromDifferentCountry() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let note = makeNote(countryCode: "IT", day: 5)
        #expect(provider.notesCount(for: trip, notes: [note]) == 0)
    }

    @Test func ignoresNoteOutsideTripDateRange() {
        let trip = makeTrip(placeCode: "FR", startDay: 10, endDay: 12)
        let beforeTrip = makeNote(countryCode: "FR", day: 5)
        let afterTrip = makeNote(countryCode: "FR", day: 20)
        #expect(provider.notesCount(for: trip, notes: [beforeTrip, afterTrip]) == 0)
    }

    @Test func countsNoteInsideTripDateRange() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let note = makeNote(countryCode: "FR", day: 5)
        #expect(provider.notesCount(for: trip, notes: [note]) == 1)
    }

    @Test func countsMultipleMatchingNotes() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let notes = [
            makeNote(countryCode: "FR", day: 2),
            makeNote(countryCode: "FR", day: 5),
            makeNote(countryCode: "FR", day: 10),
            makeNote(countryCode: "IT", day: 6), // different country
            makeNote(countryCode: nil, day: 6),  // missing code
            makeNote(countryCode: "FR", day: 99) // outside range
        ]
        #expect(provider.notesCount(for: trip, notes: notes) == 3)
    }

    @Test func countsNoteOnTripLastDayEvenLateAtNight() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        // Date inside the last trip day, just before midnight UTC.
        let lastDay = Self.date(year: 2026, month: 1, day: 10, hour: 23, minute: 50)
        let note = Note(
            id: "n-late",
            title: nil,
            text: "",
            createdAt: lastDay,
            updatedAt: lastDay,
            tripStartDate: nil,
            tripEndDate: nil,
            isBookmarked: false,
            location: NoteLocation(
                placeName: "Eiffel Tower",
                city: "Paris",
                country: "France",
                countryCode: "FR",
                latitude: 0,
                longitude: 0
            ),
            photos: [],
            headerTitle: nil
        )
        #expect(provider.notesCount(for: trip, notes: [note]) == 1)
    }

    @Test func countryCodeComparisonIsCaseInsensitive() {
        let trip = makeTrip(placeCode: "fr", startDay: 1, endDay: 10)
        let note = makeNote(countryCode: "FR", day: 5)
        #expect(provider.notesCount(for: trip, notes: [note]) == 1)
    }

    @Test func notesFilterReturnsSameSetAsCount() {
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let inside1 = makeNote(countryCode: "FR", day: 2)
        let inside2 = makeNote(countryCode: "FR", day: 9)
        let outsideCountry = makeNote(countryCode: "IT", day: 5)
        let outsideDates = makeNote(countryCode: "FR", day: 99)
        let noLocation = makeNote(countryCode: nil, location: nil, day: 5)
        let allNotes = [inside1, inside2, outsideCountry, outsideDates, noLocation]

        let filtered = provider.notes(for: trip, in: allNotes)
        #expect(filtered.count == 2)
        #expect(filtered.contains { $0.id == inside1.id })
        #expect(filtered.contains { $0.id == inside2.id })
        // The same source of truth feeds both count and screen filter.
        #expect(provider.notesCount(for: trip, notes: allNotes) == filtered.count)
    }

    @Test func prefersNoteTripStartDateOverCreatedAt() {
        // Note was created today (way outside the trip) but its trip-event
        // date sits inside the trip range — it should count.
        let trip = makeTrip(placeCode: "FR", startDay: 1, endDay: 10)
        let createdToday = Self.date(year: 2099, month: 1, day: 1)
        let tripEventDate = Self.date(year: 2026, month: 1, day: 5)
        let note = Note(
            id: "n-event",
            title: nil,
            text: "",
            createdAt: createdToday,
            updatedAt: createdToday,
            tripStartDate: tripEventDate,
            tripEndDate: tripEventDate,
            isBookmarked: false,
            location: NoteLocation(
                placeName: "Louvre",
                city: "Paris",
                country: "France",
                countryCode: "FR",
                latitude: 0,
                longitude: 0
            ),
            photos: [],
            headerTitle: nil
        )
        #expect(provider.notesCount(for: trip, notes: [note]) == 1)
    }

    // MARK: - Fixtures

    private func makeTrip(placeCode: String, startDay: Int, endDay: Int) -> Trip {
        Trip(
            id: UUID(),
            placeCode: placeCode,
            startDate: Self.date(year: 2026, month: 1, day: startDay),
            endDate: Self.date(year: 2026, month: 1, day: endDay),
            notesCount: 0,
            visitedPlaces: []
        )
    }

    private func makeNote(
        countryCode: String?,
        location: NoteLocation? = .some(.fixture()),
        day: Int
    ) -> Note {
        let resolvedLocation: NoteLocation?
        if let location {
            resolvedLocation = NoteLocation(
                placeName: location.placeName,
                city: location.city,
                country: location.country,
                countryCode: countryCode,
                latitude: location.latitude,
                longitude: location.longitude
            )
        } else {
            resolvedLocation = nil
        }
        let noteDate = Self.date(year: 2026, month: 1, day: day)
        return Note(
            id: UUID().uuidString,
            title: nil,
            text: "",
            createdAt: noteDate,
            updatedAt: noteDate,
            tripStartDate: nil,
            tripEndDate: nil,
            isBookmarked: false,
            location: resolvedLocation,
            photos: [],
            headerTitle: nil
        )
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}

private extension NoteLocation {
    static func fixture() -> NoteLocation {
        NoteLocation(
            placeName: "Place",
            city: "City",
            country: "Country",
            countryCode: nil,
            latitude: 0,
            longitude: 0
        )
    }
}
