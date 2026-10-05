//
//  PhotoTestImages.swift
//  XploraTests
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoTestImages {
    /// A JPEG with a horizontal gradient so encoders can't collapse it.
    /// `exifOrientation` 6 means "rotate 90° CW to display".
    static func jpegData(width: Int, height: Int, exifOrientation: Int? = nil) -> Data {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        for x in stride(from: 0, to: width, by: max(1, width / 16)) {
            let value = CGFloat(x) / CGFloat(width)
            context.setFillColor(red: value, green: 1 - value, blue: 0.5, alpha: 1)
            context.fill(CGRect(x: x, y: 0, width: max(1, width / 16), height: height))
        }
        let image = context.makeImage()!

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil)!
        var properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.9]
        if let exifOrientation {
            properties[kCGImagePropertyOrientation] = exifOrientation
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    /// Left half red, right half blue — lets tests check where pixels ended up
    /// after orientation is applied.
    static func splitColorImage(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        context.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
        context.fill(CGRect(x: width / 2, y: 0, width: width - width / 2, height: height))
        return context.makeImage()!
    }

    static func encode(_ image: CGImage, type: UTType, exifOrientation: Int? = nil) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, type.identifier as CFString, 1, nil)!
        var properties: [CFString: Any] = [:]
        if let exifOrientation {
            properties[kCGImagePropertyOrientation] = exifOrientation
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    /// RGBA PNG like a screenshot: alpha channel present, optionally with a
    /// fully transparent top-left quarter.
    static func pngWithAlpha(width: Int, height: Int, transparentCorner: Bool = false) -> Data {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        if transparentCorner {
            // CG origin is bottom-left; this clears the top-left quarter.
            context.clear(CGRect(x: 0, y: height / 2, width: width / 2, height: height - height / 2))
        }
        return encode(context.makeImage()!, type: .png)
    }

    /// RGB of the pixel at (x, y), with (0, 0) at the top-left.
    static func pixel(of image: CGImage, x: Int, y: Int) -> (red: UInt8, green: UInt8, blue: UInt8) {
        var bytes = [UInt8](repeating: 0, count: 4)
        let context = CGContext(
            data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        // Shift the image so the requested pixel lands on the 1×1 canvas.
        context.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
        return (bytes[0], bytes[1], bytes[2])
    }

    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("XploraPhotoTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func writeTemporaryFile(_ data: Data, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: url)
        return url
    }
}
