//
//  MapViewModel.swift
//  Xplora
//

import Foundation
import MapKit

@MainActor
protocol MapViewModelInput: AnyObject {
    func viewDidLoad()
    func didTapAddNote()
    func didTapNotes()
    func didSelectMarker(_ marker: CountryVisitMarker)
    func didSelectNote(noteId: String)
    func previewModel(for marker: CountryVisitMarker) -> TripNotePreviewViewModel
    func previewModels(forNoteIds noteIds: [String]) -> [TripNoteClusterPreview]
    func refreshMarkers()
}

/// A single card inside the cluster carousel — carries the preview view-model
/// plus the original noteId so the tap can route through `MapRoute`.
struct TripNoteClusterPreview {
    let noteId: String
    let countryCode: String
    let coordinate: LocationCoordinate
    let preview: TripNotePreviewViewModel
}

@MainActor
protocol MapViewModelOutput: AnyObject {
    var onMarkersUpdated: (([CountryVisitMarker]) -> Void)? { get set }
    var onOverlaysUpdated: (([MKOverlay]) -> Void)? { get set }
    var onRoute: ((MapRoute) -> Void)? { get set }
}

enum MapRoute {
    case addNote
    case showNotes
    case showCountryFirstNote(countryCode: String, noteId: String?, coordinate: LocationCoordinate)
}

@MainActor
final class MapViewModel: MapViewModelInput, MapViewModelOutput {
    var onMarkersUpdated: (([CountryVisitMarker]) -> Void)?
    var onOverlaysUpdated: (([MKOverlay]) -> Void)?
    var onRoute: ((MapRoute) -> Void)?

    private let getAllNotesUseCase: GetAllNotesUseCase
    private let fogOverlayProvider: FogOverlayProviding
    private let locationService: LocationService
    private var cachedNotesById: [String: Note] = [:]

    init(
        getAllNotesUseCase: GetAllNotesUseCase,
        fogOverlayProvider: FogOverlayProviding,
        locationService: LocationService
    ) {
        self.getAllNotesUseCase = getAllNotesUseCase
        self.fogOverlayProvider = fogOverlayProvider
        self.locationService = locationService
    }

    func viewDidLoad() {
        locationService.requestWhenInUseAuthorization()
        locationService.startUpdatingLocation()
        loadMarkers()
    }

    func didTapAddNote() {
        onRoute?(.addNote)
    }

    func didTapNotes() {
        onRoute?(.showNotes)
    }

    func didSelectMarker(_ marker: CountryVisitMarker) {
        let coordinate = LocationCoordinate(latitude: marker.coordinate.latitude, longitude: marker.coordinate.longitude)
        onRoute?(.showCountryFirstNote(countryCode: marker.countryCode, noteId: marker.firstNoteId, coordinate: coordinate))
    }

    func didSelectNote(noteId: String) {
        // Used by the cluster carousel: each card knows its own noteId, so we
        // don't have to fish it out of a marker. CountryCode/coordinate come
        // from the cached note's location for completeness.
        guard let note = cachedNotesById[noteId], let location = note.location else { return }
        let countryCode = (location.countryCode ?? location.country).uppercased()
        let coordinate = LocationCoordinate(latitude: location.latitude, longitude: location.longitude)
        onRoute?(.showCountryFirstNote(countryCode: countryCode, noteId: noteId, coordinate: coordinate))
    }

    func previewModel(for marker: CountryVisitMarker) -> TripNotePreviewViewModel {
        previewModel(forNoteId: marker.firstNoteId, fallbackTitle: marker.title, fallbackDateRange: marker.dateRangeText)
    }

    func previewModels(forNoteIds noteIds: [String]) -> [TripNoteClusterPreview] {
        noteIds.compactMap { noteId in
            guard let note = cachedNotesById[noteId], let location = note.location else { return nil }
            let preview = previewModel(forNoteId: noteId, fallbackTitle: location.placeName, fallbackDateRange: "")
            let countryCode = (location.countryCode ?? location.country).uppercased()
            return TripNoteClusterPreview(
                noteId: noteId,
                countryCode: countryCode,
                coordinate: LocationCoordinate(latitude: location.latitude, longitude: location.longitude),
                preview: preview
            )
        }
    }

    private func previewModel(forNoteId noteId: String?, fallbackTitle: String, fallbackDateRange: String) -> TripNotePreviewViewModel {
        let note = noteId.flatMap { cachedNotesById[$0] }
        let previewTitle = NotePresentationTitle.displayTitle(from: note?.title)
        let trimmedFallback = fallbackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let formattedDateRange = note.map { NotePresentationFactory.formattedDateRange(for: $0) } ?? fallbackDateRange
        let locationTitle = note?.location?.hasDisplayableValue == true ? note?.location?.placeName : nil
        let locationSubtitle = note?.location?.address?.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationChipText = locationTitle ?? ((locationSubtitle?.isEmpty == false) ? locationSubtitle : nil) ?? (trimmedFallback.isEmpty ? nil : trimmedFallback)
        let previewText = note
            .map { NotePresentationFactory.textPreview(for: $0) }
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? L10n.Map.Preview.openNoteHint

        return TripNotePreviewViewModel(
            title: previewTitle,
            dateRange: formattedDateRange,
            photoURLs: note?.photoURLs ?? [],
            photoOverflowCount: NotePresentationFactory.previewOverflowCount(photoCount: note?.photoURLs.count ?? 0),
            isBookmarked: note?.isBookmarked ?? false,
            locationTitle: locationTitle,
            locationSubtitle: locationSubtitle,
            locationChipText: locationChipText,
            textPreview: previewText
        )
    }

    func refreshMarkers() {
        loadMarkers()
    }

    private func loadMarkers() {
        Task {
            do {
                let notes = try await getAllNotesUseCase.execute()
                let notesWithLocation = notes.filter { $0.location != nil }
                cachedNotesById = Dictionary(uniqueKeysWithValues: notesWithLocation.map { ($0.id, $0) })
                let markers = Self.makeMarkers(from: notesWithLocation)
                onMarkersUpdated?(markers)
                onOverlaysUpdated?(fogOverlayProvider.makeOverlays(visitedCountryCodes: []))
            } catch {
                cachedNotesById = [:]
                onMarkersUpdated?([])
                onOverlaysUpdated?([])
            }
        }
    }

    /// Bucket notes by their exact coordinate (rounded to ~1 m) so notes
    /// pinned to the same spot collapse into one marker — that single marker
    /// then carries multiple `noteIds`. MapKit's own clustering further
    /// merges *nearby* markers at low zoom levels; together they cover both
    /// "identical location" and "close by" cases.
    private static func makeMarkers(from notes: [Note]) -> [CountryVisitMarker] {
        // Preserve insertion order so the latest-edited note remains the
        // marker's representative for the legacy single-tap callout.
        var orderedKeys: [CoordinateKey] = []
        var grouped: [CoordinateKey: [Note]] = [:]
        for note in notes {
            guard let key = CoordinateKey(note: note) else { continue }
            if grouped[key] == nil { orderedKeys.append(key) }
            grouped[key, default: []].append(note)
        }
        return orderedKeys.compactMap { key in
            guard let bucket = grouped[key], !bucket.isEmpty else { return nil }
            return makeMarker(forBucket: bucket)
        }
    }

    private struct CoordinateKey: Hashable {
        let lat: Int
        let lon: Int

        // ~1m on the equator. Lower precision (1e4) collapses neighbors that
        // really should be separate markers; higher precision (1e6) treats
        // sub-meter GPS jitter as distinct pins.
        private static let scale: Double = 100_000

        init?(note: Note) {
            guard let location = note.location else { return nil }
            self.lat = Int((location.latitude * Self.scale).rounded())
            self.lon = Int((location.longitude * Self.scale).rounded())
        }
    }

    private static func makeMarker(forBucket bucket: [Note]) -> CountryVisitMarker? {
        guard let representative = bucket.first, let location = representative.location else { return nil }

        let placeName = location.placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteTitle = representative.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = !placeName.isEmpty ? placeName : (!noteTitle.isEmpty ? noteTitle : L10n.Map.Marker.pinnedNote)
        let countryCode = (location.countryCode ?? location.country)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let resolvedRange = NoteDateRangeResolver.effectiveRange(
            tripStartDate: representative.tripStartDate,
            tripEndDate: representative.tripEndDate
        )
        let dateRange: String
        if let start = resolvedRange.start, let end = resolvedRange.end {
            dateRange = NoteDateRangeFormatter.displayText(startDate: start, endDate: end)
        } else {
            dateRange = markerDateFormatter.string(from: representative.updatedAt)
        }

        return CountryVisitMarker(
            countryCode: countryCode,
            title: title,
            dateRangeText: dateRange,
            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            noteIds: bucket.map(\.id)
        )
    }

    private static let markerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
