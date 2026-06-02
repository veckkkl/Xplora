//
//  NotePhotoFileStorage.swift
//  Xplora
//

import Foundation

/// Path mapping for note photo files on disk.
///
/// iOS does not guarantee that an app's container path stays stable between
/// installs / Xcode builds — storing absolute paths in CoreData causes
/// photos to "disappear" after a relaunch. This helper persists only the
/// **relative** path (e.g. `Notes/<noteId>/<file>.jpg`) and resolves it
/// against the current Application Support directory at read time.
///
/// Legacy paths that were stored as absolute (leading `/`) are still read
/// as-is for backward compatibility.
enum NotePhotoFileStorage {
    /// Resolves a stored `localPath` value into a usable file URL.
    static func absoluteURL(for localPath: String) -> URL {
        if localPath.hasPrefix("/") {
            // Legacy absolute path — keep working as long as the file is
            // still where it used to be.
            return URL(fileURLWithPath: localPath)
        }
        guard let baseURL = try? applicationSupportDirectoryURL() else {
            return URL(fileURLWithPath: localPath)
        }
        return baseURL.appendingPathComponent(localPath)
    }

    /// Converts an absolute photo URL into the relative form that we persist.
    /// If the URL is somehow outside the Application Support tree, falls back
    /// to the full path so the link isn't lost.
    static func relativePath(for absoluteURL: URL) -> String {
        guard let baseURL = try? applicationSupportDirectoryURL() else {
            return absoluteURL.path
        }
        let basePath = baseURL.standardizedFileURL.path
        let candidate = absoluteURL.standardizedFileURL.path
        guard candidate.hasPrefix(basePath) else { return candidate }
        var trimmed = String(candidate.dropFirst(basePath.count))
        while trimmed.hasPrefix("/") {
            trimmed.removeFirst()
        }
        return trimmed
    }

    /// Directory for a single note's photos, creating intermediates if missing.
    static func notesDirectoryURL(noteId: String) throws -> URL {
        let baseURL = try applicationSupportDirectoryURL()
        return baseURL
            .appendingPathComponent("Notes", isDirectory: true)
            .appendingPathComponent(noteId, isDirectory: true)
    }

    static func applicationSupportDirectoryURL() throws -> URL {
        guard let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else {
            throw NSError(domain: "NotePhotoFileStorage", code: 1)
        }
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
