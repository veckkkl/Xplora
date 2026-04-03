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
    func previewModel(for marker: CountryVisitMarker) -> TripNotePreviewViewModel
    func refreshMarkers()
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

    func previewModel(for marker: CountryVisitMarker) -> TripNotePreviewViewModel {
        let note = marker.firstNoteId.flatMap { cachedNotesById[$0] }
        let previewTitle = NotePresentationTitle.displayTitle(from: note?.title)
        let placeTitle: String?
        if let note, note.location?.hasDisplayableValue == true {
            placeTitle = note.location?.placeName
        } else {
            placeTitle = nil
        }

        return TripNotePreviewViewModel(
            title: previewTitle,
            dateRange: marker.dateRangeText,
            photoURLs: note?.photoURLs ?? [],
            isBookmarked: note?.isBookmarked ?? false,
            placeTitle: placeTitle,
            textPreview: note?.text ?? "Open note to see details."
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
                let markers = notesWithLocation.compactMap(Self.makeMarker(from:))
                onMarkersUpdated?(markers)
                onOverlaysUpdated?(fogOverlayProvider.makeOverlays(visitedCountryCodes: []))
            } catch {
                cachedNotesById = [:]
                onMarkersUpdated?([])
                onOverlaysUpdated?([])
            }
        }
    }

    private static func makeMarker(from note: Note) -> CountryVisitMarker? {
        guard let location = note.location else { return nil }

        let placeName = location.placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteTitle = note.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = !placeName.isEmpty ? placeName : (!noteTitle.isEmpty ? noteTitle : "Pinned note")
        let countryCode = location.country.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let dateRange = (note.dateRangeText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? (note.dateRangeText ?? "")
            : markerDateFormatter.string(from: note.updatedAt)

        return CountryVisitMarker(
            countryCode: countryCode,
            title: title,
            dateRangeText: dateRange,
            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            firstNoteId: note.id
        )
    }

    private static let markerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
