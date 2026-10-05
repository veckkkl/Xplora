//
//  TripPhotoImageLoaderTests.swift
//  XploraTests
//

import Foundation
import Testing
import UIKit
@testable import Xplora

@MainActor
struct TripPhotoImageLoaderTests {

    private func load(_ loader: TripPhotoImageLoader, url: URL, pixelSize: Int) async -> UIImage? {
        await withCheckedContinuation { continuation in
            loader.loadImage(from: url, pixelSize: pixelSize) { continuation.resume(returning: $0) }
        }
    }

    @Test func loadImage_returnsPreviewSizedForTile_notFullImage() async throws {
        let directory = try PhotoTestImages.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try PhotoTestImages.writeTemporaryFile(PhotoTestImages.jpegData(width: 2048, height: 1536), in: directory)
        let loader = TripPhotoImageLoader()

        let image = try #require(await load(loader, url: url, pixelSize: 200))

        let cgImage = try #require(image.cgImage)
        // 200 px rounds up to the 256 bucket; the shorter side covers it.
        #expect(min(cgImage.width, cgImage.height) >= 256)
        #expect(max(cgImage.width, cgImage.height) < 2048)
        #expect(loader.cachedImage(for: url, pixelSize: 200) != nil)
    }

    @Test func loadImage_missingFile_returnsNil() async {
        let loader = TripPhotoImageLoader()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        #expect(await load(loader, url: url, pixelSize: 200) == nil)
    }

    @Test func cache_isBounded() {
        let loader = TripPhotoImageLoader()
        #expect(loader.imageCache.totalCostLimit == TripPhotoImageLoader.defaultTotalCostLimit)
        #expect(loader.imageCache.countLimit == TripPhotoImageLoader.defaultCountLimit)
        #expect(loader.imageCache.totalCostLimit > 0)
    }

    @Test func cost_isDecodedBitmapSize() throws {
        let cgImage = try NotePhotoImageProcessor.downsampledImage(
            data: PhotoTestImages.jpegData(width: 400, height: 300),
            maxPixelSize: 400
        )
        let cost = TripPhotoImageLoader.cost(of: UIImage(cgImage: cgImage))
        #expect(cost >= 400 * 300 * 4)
    }

    @Test func bucketedPixelSize_roundsUpAndCaps() {
        #expect(TripPhotoImageLoader.bucketedPixelSize(for: 100) == 256)
        #expect(TripPhotoImageLoader.bucketedPixelSize(for: 600) == 768)
        #expect(TripPhotoImageLoader.bucketedPixelSize(for: 1290) == 1536)
        #expect(TripPhotoImageLoader.bucketedPixelSize(for: 5000) == NotePhotoImageProcessor.maxStoredPixelSize)
    }
}
