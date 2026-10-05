//
//  NotePhotoImageProcessor.swift
//  Xplora
//

import CryptoKit
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// A photo ready to be stored: downsampled, JPEG-encoded and hashed.
struct NotePreparedPhoto: Sendable {
    let jpegData: Data
    /// SHA256 of `jpegData`, used for duplicate detection.
    let contentHash: String
    let assetIdentifier: String?
}

enum NotePhotoImageError: Error {
    case unreadableImage
    case encodingFailed
}

/// Thread-safe image helpers built on ImageIO. Everything here is
/// synchronous and meant to be called off the main thread.
enum NotePhotoImageProcessor {
    /// Longest side of a stored note photo, in pixels. The largest place a
    /// photo is shown is a full-width collage tile (~1290 px on a Pro Max),
    /// so 2048 px keeps it sharp with headroom for zoom, at roughly 1/6 the
    /// pixels of a 12 MP camera original.
    static let maxStoredPixelSize = 2048
    static let jpegQuality: CGFloat = 0.82

    // MARK: - Prepare for storage

    static func preparePhoto(fromFileAt url: URL, assetIdentifier: String?) throws -> NotePreparedPhoto {
        let data = try autoreleasepool {
            let image = try downsampledImage(at: url, maxPixelSize: maxStoredPixelSize)
            return try jpegData(from: image)
        }
        return NotePreparedPhoto(jpegData: data, contentHash: sha256Hex(data), assetIdentifier: assetIdentifier)
    }

    static func preparePhoto(from image: UIImage, assetIdentifier: String?) throws -> NotePreparedPhoto {
        let data = try autoreleasepool {
            let downsampled = try downsampledImage(from: image, maxPixelSize: maxStoredPixelSize)
            return try jpegData(from: downsampled)
        }
        return NotePreparedPhoto(jpegData: data, contentHash: sha256Hex(data), assetIdentifier: assetIdentifier)
    }

    // MARK: - Downsampling

    /// Decodes the file at `url` directly at reduced size, so the
    /// full-resolution bitmap is never created. Applies EXIF orientation.
    static func downsampledImage(at url: URL, maxPixelSize: Int) throws -> CGImage {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else {
            throw NotePhotoImageError.unreadableImage
        }
        return try downsampledImage(from: source, maxPixelSize: maxPixelSize)
    }

    static func downsampledImage(data: Data, maxPixelSize: Int) throws -> CGImage {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            throw NotePhotoImageError.unreadableImage
        }
        return try downsampledImage(from: source, maxPixelSize: maxPixelSize)
    }

    /// Never upscales: the target is clamped to the source's longest side.
    static func downsampledImage(from source: CGImageSource, maxPixelSize: Int) throws -> CGImage {
        var targetPixelSize = maxPixelSize
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let width = properties[kCGImagePropertyPixelWidth] as? Int,
           let height = properties[kCGImagePropertyPixelHeight] as? Int {
            targetPixelSize = min(maxPixelSize, max(width, height))
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: targetPixelSize
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw NotePhotoImageError.unreadableImage
        }
        return image
    }

    /// Downsamples so the image's *shorter* side is at least `fillPixelSize`
    /// (when the source is that large), for aspect-fill tiles. Very wide
    /// images are capped at `maxAspectRatio` × `fillPixelSize` on the long side.
    static func aspectFillImage(at url: URL, fillPixelSize: Int, maxAspectRatio: CGFloat = 3) throws -> CGImage {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else {
            throw NotePhotoImageError.unreadableImage
        }
        return try aspectFillImage(from: source, fillPixelSize: fillPixelSize, maxAspectRatio: maxAspectRatio)
    }

    static func aspectFillImage(from source: CGImageSource, fillPixelSize: Int, maxAspectRatio: CGFloat = 3) throws -> CGImage {
        var aspectRatio: CGFloat = 1
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let width = properties[kCGImagePropertyPixelWidth] as? Int,
           let height = properties[kCGImagePropertyPixelHeight] as? Int,
           min(width, height) > 0 {
            aspectRatio = CGFloat(max(width, height)) / CGFloat(min(width, height))
        }
        let longSide = CGFloat(fillPixelSize) * min(aspectRatio, maxAspectRatio)
        return try downsampledImage(from: source, maxPixelSize: Int(longSide.rounded(.up)))
    }

    /// For images that only exist in memory (camera capture). Redraws at
    /// scale 1 into an opaque bitmap, which also bakes in `imageOrientation`.
    static func downsampledImage(from image: UIImage, maxPixelSize: Int) throws -> CGImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longestSide = max(pixelWidth, pixelHeight)
        guard longestSide > 0 else { throw NotePhotoImageError.unreadableImage }

        let ratio = min(1, CGFloat(maxPixelSize) / longestSide)
        let width = Int((pixelWidth * ratio).rounded())
        let height = Int((pixelHeight * ratio).rounded())

        // UIGraphicsImageRenderer returns a premultiplied-alpha bitmap even
        // with `opaque = true`, so draw into an opaque CGContext directly.
        guard let context = makeOpaqueContext(width: width, height: height, colorSpace: image.cgImage?.colorSpace) else {
            throw NotePhotoImageError.unreadableImage
        }
        // Flip to UIKit's top-left origin so `draw(in:)` applies orientation.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        guard let cgImage = context.makeImage() else { throw NotePhotoImageError.unreadableImage }
        return cgImage
    }

    // MARK: - Encoding / hashing

    static func jpegData(from image: CGImage, quality: CGFloat = jpegQuality) throws -> Data {
        // JPEG has no alpha; encoding an alpha bitmap makes ImageIO warn and
        // costs extra memory, so flatten those first.
        let image = try opaqueImage(image)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw NotePhotoImageError.encodingFailed
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw NotePhotoImageError.encodingFailed
        }
        return data as Data
    }

    /// Returns `image` unchanged when it has no alpha channel. Otherwise
    /// (e.g. PNG screenshots) redraws it over white into an opaque RGB bitmap.
    static func opaqueImage(_ image: CGImage) throws -> CGImage {
        guard image.hasAlphaChannel else { return image }
        guard let context = makeOpaqueContext(width: image.width, height: image.height, colorSpace: image.colorSpace) else {
            throw NotePhotoImageError.encodingFailed
        }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(rect)
        context.draw(image, in: rect)
        guard let opaque = context.makeImage() else { throw NotePhotoImageError.encodingFailed }
        return opaque
    }

    /// 8-bit RGB without alpha. Keeps the source RGB color space (e.g. Display
    /// P3) when CoreGraphics supports it, otherwise falls back to sRGB.
    private static func makeOpaqueContext(width: Int, height: Int, colorSpace: CGColorSpace?) -> CGContext? {
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
        if let colorSpace, colorSpace.model == .rgb,
           let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                   bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) {
            return context
        }
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                         bytesPerRow: 0, space: sRGB, bitmapInfo: bitmapInfo)
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

private extension CGImage {
    var hasAlphaChannel: Bool {
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }
}
