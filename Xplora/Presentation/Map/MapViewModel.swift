//
//  MapViewModel.swift
//  Xplora


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

    private let getCountryVisitMarkersUseCase: GetCountryVisitMarkersUseCase
    private let getNoteUseCase: GetNoteUseCase
    private let fogOverlayProvider: FogOverlayProviding
    private let locationService: LocationService
    private var cachedNotesById: [String: Note] = [:]

    init(
        getCountryVisitMarkersUseCase: GetCountryVisitMarkersUseCase,
        getNoteUseCase: GetNoteUseCase,
        fogOverlayProvider: FogOverlayProviding,
        locationService: LocationService
    ) {
        self.getCountryVisitMarkersUseCase = getCountryVisitMarkersUseCase
        self.getNoteUseCase = getNoteUseCase
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
        let formattedDateRange = note.map { NotePresentationFactory.formattedDateRange(for: $0) } ?? marker.dateRangeText
        return TripNotePreviewViewModel(
            title: note.map { NotePresentationFactory.title(for: $0) } ?? marker.title,
            dateRange: formattedDateRange,
            photoURLs: note?.photoURLs ?? [],
            photoOverflowCount: NotePresentationFactory.previewOverflowCount(photoCount: note?.photoURLs.count ?? 0),
            isBookmarked: note?.isBookmarked ?? false,
            locationTitle: note.flatMap { NotePresentationFactory.locationTitle(for: $0) },
            locationSubtitle: note.flatMap { NotePresentationFactory.locationSubtitle(for: $0) },
            locationChipText: note.flatMap { NotePresentationFactory.locationChipText(for: $0) } ?? marker.title,
            textPreview: note
                .map { NotePresentationFactory.textPreview(for: $0) }
                .flatMap { $0.isEmpty ? nil : $0 }
                ?? "Open note to see details."
        )
    }

    func refreshMarkers() {
        loadMarkers()
    }

    private func loadMarkers() {
        Task {
            do {
                let markers = try await getCountryVisitMarkersUseCase.execute()
                cachedNotesById = await fetchNotes(for: markers)
                onMarkersUpdated?(markers)
                onOverlaysUpdated?([])
            } catch {
                cachedNotesById = [:]
                onMarkersUpdated?([])
                onOverlaysUpdated?([])
            }
        }
    }

    private func fetchNotes(for markers: [CountryVisitMarker]) async -> [String: Note] {
        var notesById: [String: Note] = [:]

        for marker in markers {
            guard let noteId = marker.firstNoteId else { continue }
            do {
                let note = try await getNoteUseCase.execute(id: noteId)
                notesById[noteId] = note
            } catch {
                continue
            }
        }

        return notesById
    }
}
