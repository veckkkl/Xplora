//
//  FileNotePhotoStoreTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

final class FileNotePhotoStoreTests {
    private let baseURL: URL
    private let sut: FileNotePhotoStore

    init() throws {
        let baseURL = try PhotoTestImages.temporaryDirectory()
        self.baseURL = baseURL
        sut = FileNotePhotoStore(baseDirectoryURL: { baseURL })
    }

    deinit {
        try? FileManager.default.removeItem(at: baseURL)
    }

    @Test func save_returnsRelativePathInNoteDirectory() async throws {
        let path = try await sut.savePhoto(Data([1, 2, 3]), noteId: "note-1")
        #expect(path.hasPrefix("Notes/note-1/"))
        #expect(path.hasSuffix(".jpg"))
        #expect(!path.hasPrefix("/"))
    }

    @Test func saveLoadDelete_roundTrip() async throws {
        let data = Data("photo".utf8)
        let path = try await sut.savePhoto(data, noteId: "note-1")

        #expect(try await sut.loadPhotoData(at: path) == data)

        try await sut.deletePhoto(at: path)
        await #expect(throws: (any Error).self) { try await self.sut.loadPhotoData(at: path) }
    }

    @Test func contentHash_matchesPreparedPhotoHash() async throws {
        let data = Data("photo".utf8)
        let path = try await sut.savePhoto(data, noteId: "note-1")
        #expect(try await sut.contentHash(ofPhotoAt: path) == NotePhotoImageProcessor.sha256Hex(data))
    }

    @Test func deletePhoto_missingFile_doesNotThrow() async throws {
        try await sut.deletePhoto(at: "Notes/note-1/missing.jpg")
    }

    @Test func deleteAllPhotos_removesOnlyThatNotesFiles() async throws {
        let first = try await sut.savePhoto(Data([1]), noteId: "note-1")
        let second = try await sut.savePhoto(Data([2]), noteId: "note-1")
        let other = try await sut.savePhoto(Data([3]), noteId: "note-2")

        try await sut.deleteAllPhotos(noteId: "note-1")

        let noteDirectory = baseURL.appendingPathComponent("Notes/note-1")
        #expect(!FileManager.default.fileExists(atPath: noteDirectory.path))
        await #expect(throws: (any Error).self) { try await self.sut.loadPhotoData(at: first) }
        await #expect(throws: (any Error).self) { try await self.sut.loadPhotoData(at: second) }
        #expect(try await sut.loadPhotoData(at: other) == Data([3]))
    }

    @Test func deleteAllPhotos_whenNothingStored_doesNotThrow() async throws {
        try await sut.deleteAllPhotos(noteId: "never-saved")
    }

    @Test func save_whenDirectoryCannotBeCreated_throws() async throws {
        // A regular file where the "Notes" directory should be.
        try Data().write(to: baseURL.appendingPathComponent("Notes"))
        await #expect(throws: (any Error).self) {
            try await self.sut.savePhoto(Data([1]), noteId: "note-1")
        }
    }

    @Test func save_whenBaseDirectoryUnavailable_throws() async {
        struct Unavailable: Error {}
        let store = FileNotePhotoStore(baseDirectoryURL: { throw Unavailable() })
        await #expect(throws: Unavailable.self) {
            try await store.savePhoto(Data([1]), noteId: "note-1")
        }
    }

    @Test func load_legacyAbsolutePath_resolvesAsIs() async throws {
        let url = baseURL.appendingPathComponent("legacy.jpg")
        try Data([9]).write(to: url)
        #expect(try await sut.loadPhotoData(at: url.path) == Data([9]))
    }
}
