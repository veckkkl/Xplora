//
//  NotePhotoLibrarySelectionProcessor.swift
//  Xplora
//

import Foundation
import os
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct NotePhotoLibrarySelectionResult {
    let selectedAssetIdentifiers: Set<String>
    /// Prepared photos in the order the user selected them.
    let preparedPhotos: [NotePreparedPhoto]
    /// Selected items that could not be loaded or processed.
    let failedCount: Int
}

/// Turns picker / camera output into downsampled JPEGs ready for storage.
/// All work runs off the main actor.
protocol NotePhotoLibrarySelectionProcessing {
    func process(
        results: [PHPickerResult],
        existingAssetIdentifiers: Set<String>
    ) async -> NotePhotoLibrarySelectionResult

    /// Returns `nil` when the captured image could not be processed.
    func prepareCapturedPhoto(_ image: UIImage) async -> NotePreparedPhoto?
}

final class NotePhotoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessing {
    /// Each in-flight item holds at most one downsampled bitmap (~16 MB at
    /// 2048 px), so two at a time keeps import fast without memory spikes.
    private let maxConcurrentItems = 2

    func process(
        results: [PHPickerResult],
        existingAssetIdentifiers: Set<String>
    ) async -> NotePhotoLibrarySelectionResult {
        let selectedAssetIdentifiers = Set(results.compactMap(\.assetIdentifier))

        let newResults = results.filter { result in
            guard let assetIdentifier = result.assetIdentifier else { return true }
            return !existingAssetIdentifiers.contains(assetIdentifier)
        }

        let prepared = await orderedConcurrentMap(newResults, maxConcurrentTasks: maxConcurrentItems) { result in
            await Self.preparePhoto(from: result.itemProvider, assetIdentifier: result.assetIdentifier)
        }

        return NotePhotoLibrarySelectionResult(
            selectedAssetIdentifiers: selectedAssetIdentifiers,
            preparedPhotos: prepared.compactMap { $0 },
            failedCount: prepared.filter { $0 == nil }.count
        )
    }

    func prepareCapturedPhoto(_ image: UIImage) async -> NotePreparedPhoto? {
        do {
            return try NotePhotoImageProcessor.preparePhoto(from: image, assetIdentifier: nil)
        } catch {
            Logger.photos.error("Captured photo processing failed error=\(String(describing: error), privacy: .public)")
            return nil
        }
    }

    /// Loads the original as a file and downsamples it straight from disk, so
    /// the full-resolution image is never decoded into memory.
    private static func preparePhoto(from provider: NSItemProvider, assetIdentifier: String?) async -> NotePreparedPhoto? {
        let imageType = UTType.image.identifier
        guard provider.hasItemConformingToTypeIdentifier(imageType) else {
            Logger.photos.error("Picked item has no image representation")
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: imageType) { url, error in
                // The file is deleted when this handler returns, so process synchronously here.
                guard let url else {
                    let nsError = error.map { $0 as NSError }
                    Logger.photos.error(
                        "Picked photo load failed domain=\(nsError?.domain ?? "none", privacy: .public) code=\(nsError?.code ?? 0, privacy: .public)"
                    )
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    let photo = try NotePhotoImageProcessor.preparePhoto(fromFileAt: url, assetIdentifier: assetIdentifier)
                    continuation.resume(returning: photo)
                } catch {
                    Logger.photos.error("Picked photo processing failed error=\(String(describing: error), privacy: .public)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
