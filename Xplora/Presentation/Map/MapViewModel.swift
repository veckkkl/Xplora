//
//  MapViewModel.swift
//  Xplora


import Foundation
import MapKit
import UIKit

@MainActor
protocol MapViewModelInput: AnyObject {
    func viewDidLoad()
    func didTapAddNote()
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

    func didSelectMarker(_ marker: CountryVisitMarker) {
        let coordinate = LocationCoordinate(latitude: marker.coordinate.latitude, longitude: marker.coordinate.longitude)
        onRoute?(.showCountryFirstNote(countryCode: marker.countryCode, noteId: marker.firstNoteId, coordinate: coordinate))
    }

    func previewModel(for marker: CountryVisitMarker) -> TripNotePreviewViewModel {
        let note = marker.firstNoteId.flatMap { cachedNotesById[$0] }
        return TripNotePreviewViewModel(
            title: marker.title,
            dateRange: marker.dateRangeText,
            photoURLs: note?.photoURLs ?? makeMockPhotoURLs(),
            isBookmarked: note?.isBookmarked ?? false,
            placeTitle: note?.title ?? "La Fromagerie Goncourt",
            textPreview: note?.text ?? "A rainy afternoon turned into a perfect evening. We found a tiny café, tried local cheese, and watched the city lights reflect on the wet streets."
        )
    }

    func refreshMarkers() {
        loadMarkers()
    }

    private func makeMockPhotoURLs() -> [URL] {
        let colors: [UIColor] = [
            UIColor.systemOrange,
            UIColor.systemPink,
            UIColor.systemBlue
        ]
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("map_preview_photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }

        return colors.enumerated().compactMap { index, color in
            let fileURL = tempDirectory.appendingPathComponent("preview_\(index).png")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600))
            let image = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: CGSize(width: 600, height: 600)))
            }
            guard let data = image.pngData() else { return nil }
            try? data.write(to: fileURL)
            return fileURL
        }
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
