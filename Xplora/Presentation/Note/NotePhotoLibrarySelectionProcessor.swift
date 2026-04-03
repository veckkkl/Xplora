//
//  NotePhotoLibrarySelectionProcessor.swift
//  Xplora
//

import Foundation
import PhotosUI
import UIKit

struct NotePhotoLibrarySelectionResult {
    let selectedAssetIdentifiers: Set<String>
    let newlyPickedPhotos: [NotePickedPhoto]
}

protocol NotePhotoLibrarySelectionProcessing {
    func process(
        results: [PHPickerResult],
        existingAssetIdentifiers: Set<String>
    ) async -> NotePhotoLibrarySelectionResult
}

final class NotePhotoLibrarySelectionProcessor: NotePhotoLibrarySelectionProcessing {
    func process(
        results: [PHPickerResult],
        existingAssetIdentifiers: Set<String>
    ) async -> NotePhotoLibrarySelectionResult {
        let selectedAssetIdentifiers = Set(results.compactMap(\.assetIdentifier))

        let pickedPhotos = await withTaskGroup(of: NotePickedPhoto?.self) { group in
            for result in results {
                if let assetIdentifier = result.assetIdentifier,
                   existingAssetIdentifiers.contains(assetIdentifier) {
                    continue
                }

                let provider = result.itemProvider
                guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
                let assetIdentifier = result.assetIdentifier

                group.addTask {
                    guard let image = await Self.loadImage(from: provider) else { return nil }
                    return NotePickedPhoto(image: image, assetIdentifier: assetIdentifier)
                }
            }

            var photos: [NotePickedPhoto] = []
            for await photo in group {
                guard let photo else { continue }
                photos.append(photo)
            }
            return photos
        }

        return NotePhotoLibrarySelectionResult(
            selectedAssetIdentifiers: selectedAssetIdentifiers,
            newlyPickedPhotos: pickedPhotos
        )
    }

    private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}
