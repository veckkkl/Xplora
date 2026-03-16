//
//  NotesRepoImpl.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation
import UIKit

actor NotesStore {
    private var notes: [String: Note] = [:]

    func get(id: String) -> Note? {
        notes[id]
    }

    func save(_ note: Note) {
        notes[note.id] = note
    }

    func delete(id: String) {
        notes.removeValue(forKey: id)
    }
}

final class NotesRepoImpl: NotesRepo {
    private let store: NotesStore

    init(store: NotesStore = NotesStore()) {
        self.store = store
        Task {
            await store.seedIfNeeded()
        }
    }

    func getNote(id: String) async throws -> Note {
        if let note = await store.get(id: id) {
            return note
        }
        throw NoteRepositoryError.notFound
    }

    func save(note: Note) async throws -> Note {
        await store.save(note)
        return note
    }

    func delete(noteId: String) async throws {
        await store.delete(id: noteId)
    }
}

extension NotesStore {
    func seedIfNeeded() async {
        if notes.isEmpty {
            let samples = SampleNoteFactory.makeSampleNotes()
            for note in samples {
                notes[note.id] = note
            }
        }
    }
}

private enum SampleNoteFactory {
    static func makeSampleNotes() -> [Note] {
        let parisCoordinate = LocationCoordinate(latitude: 48.8566, longitude: 2.3522)
        let barcelonaCoordinate = LocationCoordinate(latitude: 41.3851, longitude: 2.1734)
        let parisDate = makeDate(day: 17, month: 8, year: 2024)
        let barcelonaDate = makeDate(day: 20, month: 9, year: 2021)

        let parisPhotos = makeSamplePhotoURLs(prefix: "paris", colors: [
            (0.95, 0.72, 0.26),
            (0.22, 0.55, 0.95),
            (0.96, 0.46, 0.58)
        ])
        let barcelonaPhotos = makeSamplePhotoURLs(prefix: "barcelona", colors: [
            (0.95, 0.72, 0.26),
            (0.22, 0.55, 0.95),
            (0.96, 0.46, 0.58)
        ])

        let parisNote = Note(
            id: "note-paris-1",
            coordinate: parisCoordinate,
            title: "La Fromagerie Goncourt",
            text: "Fromagerie Goncourt on Rue Oberkampf — the smell was profound, earthy and sharp. The cheesemonger cut a sliver of Comté for me to taste. The flavor unfolded slowly — nutty at first, then deeper, almost caramelized, with a warm, lingering finish that stayed long after the bite was gone.\nOutside, the rain had just stopped, leaving Rue Oberkampf slick and shimmering under the streetlights. We carried our paper-wrapped treasure down the street, unable to resist tearing off another piece before we even reached the corner. There was something quietly perfect about that moment — the hum of evening conversations spilling from cafés, the faint scent of damp stone, and the taste of aged Comté melting into memory.",
            photoURLs: parisPhotos,
            createdAt: parisDate,
            updatedAt: parisDate,
            city: "Paris",
            country: "France",
            location: NoteLocation(
                placeName: "La Fromagerie Goncourt",
                address: "Rue Oberkampf, Paris, France",
                latitude: parisCoordinate.latitude,
                longitude: parisCoordinate.longitude
            ),
            isBookmarked: false,
            dateRangeText: "14 aug 2024 - 17 aug 2024",
            headerTitle: nil
        )

        let barcelonaNote = Note(
            id: "note-barcelona-1",
            coordinate: barcelonaCoordinate,
            title: "La Fromagerie Goncourt",
            text: "Fromagerie Goncourt on Rue Oberkampf — the smell was profound, earthy and sharp. The cheesemonger cut a sliver of Comté for me to taste. The flavor unfolded slowly — nutty at first, then deeper, almost caramelized, with a warm, lingering finish that stayed long after the bite was gone.\nOutside, the rain had just stopped, leaving Rue Oberkampf slick and shimmering under the streetlights. We carried our paper-wrapped treasure down the street, unable to resist tearing off another piece before we even reached the corner. There was something quietly perfect about that moment — the hum of evening conversations spilling from cafés, the faint scent of damp stone, and the taste of aged Comté melting into memory.",
            photoURLs: barcelonaPhotos,
            createdAt: barcelonaDate,
            updatedAt: barcelonaDate,
            city: "Barcelona",
            country: "Spain",
            location: NoteLocation(
                placeName: "La Fromagerie Goncourt",
                address: "Barcelona, Spain",
                latitude: barcelonaCoordinate.latitude,
                longitude: barcelonaCoordinate.longitude
            ),
            isBookmarked: false,
            dateRangeText: "13 sep 2021 - 20 sep 2021",
            headerTitle: nil
        )

        return [parisNote, barcelonaNote]
    }

    private static func makeDate(day: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func makeSamplePhotoURLs(prefix: String, colors: [(CGFloat, CGFloat, CGFloat)]) -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("sample_note_photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempDir.path) {
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }

        return colors.enumerated().compactMap { index, color in
            let fileURL = tempDir.appendingPathComponent("\(prefix)_\(index).png")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
            guard let image = makeSolidImage(color: color, size: CGSize(width: 600, height: 400)),
                  let data = image.pngData() else {
                return nil
            }
            try? data.write(to: fileURL)
            return fileURL
        }
    }

    private static func makeSolidImage(color: (CGFloat, CGFloat, CGFloat), size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(red: color.0, green: color.1, blue: color.2, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
