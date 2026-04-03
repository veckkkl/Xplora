//
//  TripPhotoImageLoader.swift
//  Xplora
//

import Foundation
import UIKit

protocol TripPhotoImageLoading: AnyObject {
    func cachedImage(for url: URL) -> UIImage?
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void)
}

final class TripPhotoImageLoader: TripPhotoImageLoading {
    static let shared = TripPhotoImageLoader()

    private let imageCache = NSCache<NSURL, UIImage>()
    private let imageLoadingQueue = DispatchQueue(label: "TripPhotoImageLoader.queue", qos: .userInitiated)
    private let imageLoadingLock = NSLock()
    private var imageLoadingCallbacks: [URL: [(UIImage?) -> Void]] = [:]

    func cachedImage(for url: URL) -> UIImage? {
        imageCache.object(forKey: url as NSURL)
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache.object(forKey: url as NSURL) {
            completion(cachedImage)
            return
        }

        imageLoadingLock.lock()
        if imageLoadingCallbacks[url] != nil {
            imageLoadingCallbacks[url]?.append(completion)
            imageLoadingLock.unlock()
            return
        }
        imageLoadingCallbacks[url] = [completion]
        imageLoadingLock.unlock()

        imageLoadingQueue.async { [weak self] in
            guard let self else { return }
            let image = Self.loadImageOffMainThread(from: url)
            if let image {
                self.imageCache.setObject(image, forKey: url as NSURL)
            }

            self.imageLoadingLock.lock()
            let callbacks = self.imageLoadingCallbacks.removeValue(forKey: url) ?? []
            self.imageLoadingLock.unlock()

            guard !callbacks.isEmpty else { return }
            DispatchQueue.main.async {
                callbacks.forEach { $0(image) }
            }
        }
    }

    private static func loadImageOffMainThread(from url: URL) -> UIImage? {
        if url.isFileURL {
            return UIImage(contentsOfFile: url.path)
        }
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}
