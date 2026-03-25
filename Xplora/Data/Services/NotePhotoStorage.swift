//
//  NotePhotoStorage.swift
//  Xplora
//

import Foundation
import UIKit

protocol NotePhotoStorage {
    func save(image: UIImage, noteId: String, photoId: String, orderIndex: Int) throws -> NotePhoto
    func deletePhoto(localPath: String) throws
    func deletePhotos(localPaths: [String]) throws
    func deleteNoteDirectory(noteId: String) throws
    func fileURL(for localPath: String) -> URL
}

enum NotePhotoStorageError: Error {
    case cannotEncodeImage
    case cannotResolveApplicationSupport
}

final class NotePhotoStorageImpl: NotePhotoStorage {
    private let fileManager: FileManager
    private let compressionQuality: CGFloat

    init(fileManager: FileManager = .default, compressionQuality: CGFloat = 0.82) {
        self.fileManager = fileManager
        self.compressionQuality = compressionQuality
    }

    func save(image: UIImage, noteId: String, photoId: String, orderIndex: Int) throws -> NotePhoto {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw NotePhotoStorageError.cannotEncodeImage
        }

        let noteDirectoryURL = try noteDirectoryURL(noteId: noteId)
        if !fileManager.fileExists(atPath: noteDirectoryURL.path) {
            try fileManager.createDirectory(at: noteDirectoryURL, withIntermediateDirectories: true)
        }

        let fileName = "\(photoId).jpg"
        let relativePath = notesDirectoryName + "/" + noteId + "/" + fileName
        let fileURL = noteDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
        try data.write(to: fileURL, options: .atomic)

        return NotePhoto(
            id: photoId,
            localPath: relativePath,
            createdAt: Date(),
            orderIndex: orderIndex
        )
    }

    func deletePhoto(localPath: String) throws {
        let fileURL = fileURL(for: localPath)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    func deletePhotos(localPaths: [String]) throws {
        for localPath in Set(localPaths) {
            try deletePhoto(localPath: localPath)
        }
    }

    func deleteNoteDirectory(noteId: String) throws {
        let directoryURL = try noteDirectoryURL(noteId: noteId)
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.removeItem(at: directoryURL)
    }

    func fileURL(for localPath: String) -> URL {
        if localPath.hasPrefix("/") {
            return URL(fileURLWithPath: localPath)
        }
        if let baseURL = try? applicationSupportDirectoryURL() {
            return baseURL.appendingPathComponent(localPath, isDirectory: false)
        }
        return URL(fileURLWithPath: localPath)
    }

    private func noteDirectoryURL(noteId: String) throws -> URL {
        let baseURL = try applicationSupportDirectoryURL()
        return baseURL
            .appendingPathComponent(notesDirectoryName, isDirectory: true)
            .appendingPathComponent(noteId, isDirectory: true)
    }

    private func applicationSupportDirectoryURL() throws -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NotePhotoStorageError.cannotResolveApplicationSupport
        }
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        return baseURL
    }

    private let notesDirectoryName = "Notes"
}
