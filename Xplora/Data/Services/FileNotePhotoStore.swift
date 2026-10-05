//
//  FileNotePhotoStore.swift
//  Xplora
//

import Foundation
import os

final class FileNotePhotoStore: NotePhotoStore {
    private static let notesDirectoryName = "Notes"

    private let baseDirectoryURL: @Sendable () throws -> URL

    /// - Parameter baseDirectoryURL: Root that relative paths resolve
    ///   against. Defaults to Application Support, matching `NotePhotoFileStorage`.
    init(baseDirectoryURL: @escaping @Sendable () throws -> URL = { try NotePhotoFileStorage.applicationSupportDirectoryURL() }) {
        self.baseDirectoryURL = baseDirectoryURL
    }

    func savePhoto(_ jpegData: Data, noteId: String) async throws -> String {
        let relativePath = "\(Self.notesDirectoryName)/\(noteId)/\(UUID().uuidString).jpg"
        do {
            let fileURL = try resolve(relativePath)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try jpegData.write(to: fileURL, options: .atomic)
            return relativePath
        } catch {
            Self.log("save", error)
            throw error
        }
    }

    func loadPhotoData(at localPath: String) async throws -> Data {
        do {
            return try Data(contentsOf: resolve(localPath))
        } catch {
            Self.log("load", error)
            throw error
        }
    }

    func contentHash(ofPhotoAt localPath: String) async throws -> String {
        let data = try await loadPhotoData(at: localPath)
        return NotePhotoImageProcessor.sha256Hex(data)
    }

    func deletePhoto(at localPath: String) async throws {
        do {
            try removeItemIfPresent(at: resolve(localPath))
        } catch {
            Self.log("delete", error)
            throw error
        }
    }

    func deleteAllPhotos(noteId: String) async throws {
        do {
            let directoryURL = try baseDirectoryURL()
                .appendingPathComponent(Self.notesDirectoryName, isDirectory: true)
                .appendingPathComponent(noteId, isDirectory: true)
            try removeItemIfPresent(at: directoryURL)
        } catch {
            Self.log("deleteAll", error)
            throw error
        }
    }

    // MARK: - Private

    private func resolve(_ localPath: String) throws -> URL {
        if localPath.hasPrefix("/") {
            // Legacy absolute path stored by older builds.
            return URL(fileURLWithPath: localPath)
        }
        return try baseDirectoryURL().appendingPathComponent(localPath)
    }

    private func removeItemIfPresent(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }

    /// Logs only the operation and error code — never paths or note content.
    private static func log(_ operation: String, _ error: Error) {
        let nsError = error as NSError
        Logger.photos.error(
            "Photo file \(operation, privacy: .public) failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
        )
    }
}
