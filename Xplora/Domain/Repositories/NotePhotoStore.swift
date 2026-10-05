//
//  NotePhotoStore.swift
//  Xplora
//

import Foundation

/// File storage for note photos. Paths are the `NotePhoto.localPath` values
/// persisted in Core Data (relative, or legacy absolute).
/// Implementations do their I/O off the caller's actor.
protocol NotePhotoStore: AnyObject, Sendable {
    /// Writes JPEG data for `noteId` and returns the relative path to persist.
    func savePhoto(_ jpegData: Data, noteId: String) async throws -> String
    func loadPhotoData(at localPath: String) async throws -> Data
    /// SHA256 of the stored bytes, comparable with `NotePreparedPhoto.contentHash`.
    func contentHash(ofPhotoAt localPath: String) async throws -> String
    /// Deleting a file that no longer exists is not an error.
    func deletePhoto(at localPath: String) async throws
    /// Removes every photo file stored for `noteId`.
    func deleteAllPhotos(noteId: String) async throws
}
