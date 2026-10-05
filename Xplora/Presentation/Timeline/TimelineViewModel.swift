//
//  TimelineViewModel.swift
//  Xplora
//

import Foundation
import os

struct TripTimelineItem: Equatable {
    let id: UUID
    let flag: String
    let countryName: String
    let dateRangeText: String
    let notesText: String?
}

struct TripTimelineSection: Equatable {
    let year: Int
    let items: [TripTimelineSection.Item]

    typealias Item = TripTimelineItem
}

struct TimelineViewState: Equatable {
    let isLoading: Bool
    let sections: [TripTimelineSection]
    /// True only when trips were loaded and there are none.
    let isEmpty: Bool
    /// Set when trips couldn't be loaded; shown instead of the empty state.
    var errorMessage: String? = nil
}

enum TimelineRoute {
    case addTrip
    case editTripDates(tripId: UUID, place: CatalogPlace, startDate: Date, endDate: Date)
    case showTripNotes(trip: Trip, place: CatalogPlace)
}

@MainActor
protocol TimelineViewModelInput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapAdd()
    func didTapEditDates(tripId: UUID)
    func didConfirmDelete(tripId: UUID)
    func didTapNotes(tripId: UUID)
    func refresh()
}

@MainActor
protocol TimelineViewModelOutput: AnyObject {
    var onStateChange: ((TimelineViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onRoute: ((TimelineRoute) -> Void)? { get set }
}

@MainActor
final class TimelineViewModel: TimelineViewModelInput, TimelineViewModelOutput {
    var onStateChange: ((TimelineViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onRoute: ((TimelineRoute) -> Void)?

    private let getTripsUseCase: GetTripsUseCase
    private let getCatalogPlaces: GetCatalogPlacesUseCase
    private let getAllNotesUseCase: GetAllNotesUseCase
    private let deleteTripUseCase: DeleteTripUseCase
    private let tripNotesCountProvider: TripNotesCountProviding
    private var trips: [Trip] = []
    private var notes: [Note] = []
    private var catalogByCode: [String: CatalogPlace] = [:]
    private var isLoading = false
    private var loadErrorMessage: String?

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter
    }()

    init(
        getTripsUseCase: GetTripsUseCase,
        getCatalogPlaces: GetCatalogPlacesUseCase,
        getAllNotesUseCase: GetAllNotesUseCase,
        deleteTripUseCase: DeleteTripUseCase,
        tripNotesCountProvider: TripNotesCountProviding
    ) {
        self.getTripsUseCase = getTripsUseCase
        self.getCatalogPlaces = getCatalogPlaces
        self.getAllNotesUseCase = getAllNotesUseCase
        self.deleteTripUseCase = deleteTripUseCase
        self.tripNotesCountProvider = tripNotesCountProvider
    }

    func viewDidLoad() {
        load()
    }

    func viewWillAppear() {
        load()
    }

    func refresh() {
        load()
    }

    func didTapAdd() {
        onRoute?(.addTrip)
    }

    func didTapEditDates(tripId: UUID) {
        guard let trip = trips.first(where: { $0.id == tripId }) else { return }
        let place = catalogPlace(for: trip.placeCode)
        onRoute?(
            .editTripDates(
                tripId: trip.id,
                place: place,
                startDate: trip.startDate,
                endDate: trip.endDate
            )
        )
    }

    func didTapNotes(tripId: UUID) {
        guard let trip = trips.first(where: { $0.id == tripId }) else { return }
        // Defensive: only route when there is at least one matching note. The
        // cell already hides the tap target in that case, but a stale tap
        // race (reload between configure and tap) shouldn't open an empty
        // screen.
        guard tripNotesCountProvider.notesCount(for: trip, notes: notes) > 0 else { return }
        let place = catalogPlace(for: trip.placeCode)
        onRoute?(.showTripNotes(trip: trip, place: place))
    }

    func didConfirmDelete(tripId: UUID) {
        Task {
            do {
                try await deleteTripUseCase.execute(tripId: tripId)
                load()
            } catch {
                onError?(L10n.Timeline.Delete.error)
            }
        }
    }

    private func load() {
        isLoading = true
        publish()

        Task {
            await performLoad()
        }
    }

    /// Internal so tests can await a load.
    func performLoad() async {
        do {
            async let tripsTask = getTripsUseCase.execute()
            async let placesTask = getCatalogPlaces.execute()
            async let notesTask = loadNotesForCounts()
            let (loadedTrips, loadedPlaces) = try await (tripsTask, placesTask)
            trips = loadedTrips
            notes = await notesTask
            catalogByCode = Dictionary(
                uniqueKeysWithValues: loadedPlaces.map { ($0.code.uppercased(), $0) }
            )
            loadErrorMessage = nil
        } catch {
            let nsError = error as NSError
            Logger.storage.error(
                "Timeline load failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            trips = []
            notes = []
            catalogByCode = [:]
            loadErrorMessage = L10n.Timeline.Error.load
        }
        isLoading = false
        publish()
    }

    /// Notes only feed the per-trip counts. If they can't be read (e.g. the
    /// notes store is unavailable) trips are still shown, without counts —
    /// hiding the trips would misrepresent data that loaded fine.
    private func loadNotesForCounts() async -> [Note] {
        do {
            return try await getAllNotesUseCase.execute()
        } catch {
            let nsError = error as NSError
            Logger.storage.error(
                "Timeline notes load failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            return []
        }
    }

    private func publish() {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: trips) { trip in
            calendar.component(.year, from: trip.startDate)
        }

        let sections = grouped
            .sorted { $0.key > $1.key }
            .map { year, yearTrips -> TripTimelineSection in
                let items = yearTrips
                    .sorted { $0.startDate > $1.startDate }
                    .map(makeItem(from:))
                return TripTimelineSection(year: year, items: items)
            }

        let errorMessage = isLoading ? nil : loadErrorMessage
        onStateChange?(
            TimelineViewState(
                isLoading: isLoading,
                sections: sections,
                isEmpty: !isLoading && errorMessage == nil && sections.isEmpty,
                errorMessage: errorMessage
            )
        )
    }

    private func makeItem(from trip: Trip) -> TripTimelineItem {
        let place = catalogPlace(for: trip.placeCode)
        let count = tripNotesCountProvider.notesCount(for: trip, notes: notes)
        return TripTimelineItem(
            id: trip.id,
            flag: place.flag,
            countryName: place.localizedName,
            dateRangeText: formatRange(start: trip.startDate, end: trip.endDate),
            notesText: notesText(for: count)
        )
    }

    private func catalogPlace(for code: String) -> CatalogPlace {
        if let hit = catalogByCode[code.uppercased()] { return hit }
        return CatalogPlace(code: code.uppercased(), status: .territory)
    }

    private func formatRange(start: Date, end: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let startText = Self.dayMonthFormatter.string(from: start)
        if calendar.isDate(start, inSameDayAs: end) { return startText }
        let endText = Self.dayMonthFormatter.string(from: end)
        return "\(startText) – \(endText)"
    }

    private func notesText(for count: Int) -> String? {
        guard count > 0 else { return nil }
        // Pure-Swift plural picking — Xcode 16's PBXFileSystemSynchronizedRootGroup
        // is unreliable about bundling .stringsdict files, which made the
        // dictionary-driven fallback return "1 заметок" instead of "1 заметка".
        // Branching on the active locale picks the correct CLDR form against
        // explicit `.one / .few / .many` keys in Localizable.strings.
        switch Self.pluralCategory(count: count, locale: .autoupdatingCurrent) {
        case .one:
            return L10n.Timeline.Trip.Notes.one(count)
        case .few:
            return L10n.Timeline.Trip.Notes.few(count)
        case .many:
            return L10n.Timeline.Trip.Notes.many(count)
        case .other:
            return L10n.Timeline.Trip.Notes.other(count)
        }
    }

    private enum PluralCategory {
        case one, few, many, other
    }

    /// CLDR-style plural category for the languages we support. East-Slavic
    /// languages (ru/uk/be) need one/few/many; everything else collapses to
    /// the English-style one/other split.
    private static func pluralCategory(count: Int, locale: Locale) -> PluralCategory {
        let language = locale.language.languageCode?.identifier ?? ""
        let eastSlavic: Set<String> = ["ru", "uk", "be"]
        guard eastSlavic.contains(language) else {
            return count == 1 ? .one : .other
        }
        let mod10 = abs(count) % 10
        let mod100 = abs(count) % 100
        if mod10 == 1 && mod100 != 11 { return .one }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return .few }
        return .many
    }
}
