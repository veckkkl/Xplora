//
//  TripPhotoImageLoader.swift
//  Xplora
//

import Foundation
import ImageIO
import os
import UIKit

protocol TripPhotoImageLoading: AnyObject {
    /// `pixelSize` is the longest side of the aspect-fill tile, in pixels.
    func cachedImage(for url: URL, pixelSize: Int) -> UIImage?
    func loadImage(from url: URL, pixelSize: Int, completion: @escaping (UIImage?) -> Void)
}

/// Loads downsampled, pre-decoded previews off the main thread and keeps
/// them in a cost-bounded cache.
final class TripPhotoImageLoader: TripPhotoImageLoading {
    static let shared = TripPhotoImageLoader()

    /// Requested sizes are rounded up to one of these so different tiles of
    /// similar size share cache entries.
    static let pixelSizeBuckets = [256, 512, 768, 1024, 1536, NotePhotoImageProcessor.maxStoredPixelSize]
    static let defaultTotalCostLimit = 64 * 1024 * 1024
    static let defaultCountLimit = 100

    let imageCache = NSCache<NSString, UIImage>()
    private let imageLoadingQueue = DispatchQueue(label: "TripPhotoImageLoader.queue", qos: .userInitiated)
    private let imageLoadingLock = NSLock()
    private var imageLoadingCallbacks: [NSString: [(UIImage?) -> Void]] = [:]

    init(
        totalCostLimit: Int = TripPhotoImageLoader.defaultTotalCostLimit,
        countLimit: Int = TripPhotoImageLoader.defaultCountLimit
    ) {
        imageCache.totalCostLimit = totalCostLimit
        imageCache.countLimit = countLimit
    }

    func cachedImage(for url: URL, pixelSize: Int) -> UIImage? {
        imageCache.object(forKey: Self.cacheKey(for: url, pixelSize: pixelSize))
    }

    func loadImage(from url: URL, pixelSize: Int, completion: @escaping (UIImage?) -> Void) {
        let bucketedPixelSize = Self.bucketedPixelSize(for: pixelSize)
        let key = Self.cacheKey(for: url, pixelSize: pixelSize)
        if let cachedImage = imageCache.object(forKey: key) {
            completion(cachedImage)
            return
        }

        imageLoadingLock.lock()
        if imageLoadingCallbacks[key] != nil {
            imageLoadingCallbacks[key]?.append(completion)
            imageLoadingLock.unlock()
            return
        }
        imageLoadingCallbacks[key] = [completion]
        imageLoadingLock.unlock()

        imageLoadingQueue.async { [weak self] in
            guard let self else { return }
            let image = Self.loadImageOffMainThread(from: url, fillPixelSize: bucketedPixelSize)
            if let image {
                self.imageCache.setObject(image, forKey: key, cost: Self.cost(of: image))
            }

            self.imageLoadingLock.lock()
            let callbacks = self.imageLoadingCallbacks.removeValue(forKey: key) ?? []
            self.imageLoadingLock.unlock()

            guard !callbacks.isEmpty else { return }
            DispatchQueue.main.async {
                callbacks.forEach { $0(image) }
            }
        }
    }

    // MARK: - Helpers

    static func bucketedPixelSize(for requested: Int) -> Int {
        pixelSizeBuckets.first { $0 >= requested } ?? pixelSizeBuckets[pixelSizeBuckets.count - 1]
    }

    /// Decoded bitmap size in bytes.
    static func cost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }

    private static func cacheKey(for url: URL, pixelSize: Int) -> NSString {
        "\(url.absoluteString)#\(bucketedPixelSize(for: pixelSize))" as NSString
    }

    private static func loadImageOffMainThread(from url: URL, fillPixelSize: Int) -> UIImage? {
        do {
            let cgImage: CGImage
            if url.isFileURL {
                cgImage = try NotePhotoImageProcessor.aspectFillImage(at: url, fillPixelSize: fillPixelSize)
            } else {
                let data = try Data(contentsOf: url)
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                    throw NotePhotoImageError.unreadableImage
                }
                cgImage = try NotePhotoImageProcessor.aspectFillImage(from: source, fillPixelSize: fillPixelSize)
            }
            return UIImage(cgImage: cgImage)
        } catch {
            Logger.photos.error("Photo preview load failed error=\(String(describing: type(of: error)), privacy: .public)")
            return nil
        }
    }
}
