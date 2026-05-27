//
//  TimelineViewModel.swift
//  Xplora
//

import Foundation

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
    let isEmpty: Bool
}

enum TimelineRoute {
    case addTrip
    case editTripDates(tripId: UUID, place: CatalogPlace, startDate: Date, endDate: Date)
}

@MainActor
protocol TimelineViewModelInput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapAdd()
    func didTapEditDates(tripId: UUID)
    func didConfirmDelete(tripId: UUID)
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
    private let deleteTripUseCase: DeleteTripUseCase
    private var trips: [Trip] = []
    /// Indexed by uppercased place code so display lookups stay O(1) per row.
    private var catalogByCode: [String: CatalogPlace] = [:]
    private var isLoading = false

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter
    }()

    init(
        getTripsUseCase: GetTripsUseCase,
        getCatalogPlaces: GetCatalogPlacesUseCase,
        deleteTripUseCase: DeleteTripUseCase
    ) {
        self.getTripsUseCase = getTripsUseCase
        self.getCatalogPlaces = getCatalogPlaces
        self.deleteTripUseCase = deleteTripUseCase
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
            do {
                async let tripsTask = getTripsUseCase.execute()
                async let placesTask = getCatalogPlaces.execute()
                let (loadedTrips, loadedPlaces) = try await (tripsTask, placesTask)
                trips = loadedTrips
                catalogByCode = Dictionary(
                    uniqueKeysWithValues: loadedPlaces.map { ($0.code.uppercased(), $0) }
                )
                isLoading = false
                publish()
            } catch {
                isLoading = false
                trips = []
                catalogByCode = [:]
                publish()
                onError?(L10n.Timeline.Error.load)
            }
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

        onStateChange?(
            TimelineViewState(
                isLoading: isLoading,
                sections: sections,
                isEmpty: !isLoading && sections.isEmpty
            )
        )
    }

    private func makeItem(from trip: Trip) -> TripTimelineItem {
        let place = catalogPlace(for: trip.placeCode)
        return TripTimelineItem(
            id: trip.id,
            flag: place.flag,
            countryName: place.localizedName,
            dateRangeText: formatRange(start: trip.startDate, end: trip.endDate),
            notesText: notesText(for: trip.notesCount)
        )
    }

    /// Resolves a stored trip code against the catalog. Falls back to a synthetic
    /// `CatalogPlace` so the cell still renders (flag from the raw code, name =
    /// code) when a previously saved place is no longer in the allowlist.
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
        return count == 1
            ? L10n.Timeline.Trip.Notes.one
            : L10n.Timeline.Trip.Notes.other(count)
    }
}
