//
//  NotePhotoImageProcessorTests.swift
//  XploraTests
//

import Foundation
import ImageIO
import Testing
import UIKit
@testable import Xplora

struct NotePhotoImageProcessorTests {

    // MARK: - Downsampling

    @Test func downsample_largeImage_isLimitedToMaxPixelSize() throws {
        let data = PhotoTestImages.jpegData(width: 4000, height: 3000)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(max(image.width, image.height) == 2048)
    }

    @Test func downsample_preservesAspectRatio() throws {
        let data = PhotoTestImages.jpegData(width: 4000, height: 3000)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        let ratio = Double(image.width) / Double(image.height)
        #expect(abs(ratio - 4.0 / 3.0) < 0.01)
    }

    @Test func downsample_smallImage_isNotUpscaled() throws {
        let data = PhotoTestImages.jpegData(width: 800, height: 600)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(image.width == 800)
        #expect(image.height == 600)
    }

    @Test func downsample_appliesExifOrientation() throws {
        // Stored landscape, displayed portrait (orientation 6 = rotate 90°).
        let data = PhotoTestImages.jpegData(width: 400, height: 200, exifOrientation: 6)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(image.width == 200)
        #expect(image.height == 400)
    }

    @Test func downsample_invalidData_throws() {
        #expect(throws: NotePhotoImageError.self) {
            try NotePhotoImageProcessor.downsampledImage(data: Data("not an image".utf8), maxPixelSize: 2048)
        }
    }

    @Test func aspectFill_coversTileWithShorterSide() throws {
        let directory = try PhotoTestImages.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try PhotoTestImages.writeTemporaryFile(PhotoTestImages.jpegData(width: 2000, height: 1000), in: directory)

        let image = try NotePhotoImageProcessor.aspectFillImage(at: url, fillPixelSize: 300)

        #expect(min(image.width, image.height) >= 300)
        #expect(max(image.width, image.height) <= 600)
    }

    // MARK: - Prepare for storage

    @Test func preparePhotoFromFile_producesDownsampledJPEG() throws {
        let directory = try PhotoTestImages.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try PhotoTestImages.writeTemporaryFile(PhotoTestImages.jpegData(width: 4032, height: 3024), in: directory)

        let prepared = try NotePhotoImageProcessor.preparePhoto(fromFileAt: url, assetIdentifier: "asset-1")

        let stored = try NotePhotoImageProcessor.downsampledImage(data: prepared.jpegData, maxPixelSize: 10_000)
        #expect(max(stored.width, stored.height) == NotePhotoImageProcessor.maxStoredPixelSize)
        #expect(prepared.assetIdentifier == "asset-1")
        #expect(prepared.contentHash == NotePhotoImageProcessor.sha256Hex(prepared.jpegData))
    }

    @Test func preparePhoto_sameSource_producesSameHash() throws {
        let directory = try PhotoTestImages.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = PhotoTestImages.jpegData(width: 3000, height: 2000)
        let first = try PhotoTestImages.writeTemporaryFile(source, in: directory)
        let second = try PhotoTestImages.writeTemporaryFile(source, in: directory)

        let a = try NotePhotoImageProcessor.preparePhoto(fromFileAt: first, assetIdentifier: nil)
        let b = try NotePhotoImageProcessor.preparePhoto(fromFileAt: second, assetIdentifier: nil)

        #expect(a.contentHash == b.contentHash)
    }

    @Test func preparePhotoFromUIImage_downsamplesAndAppliesOrientation() throws {
        let data = PhotoTestImages.jpegData(width: 4000, height: 3000)
        let cgImage = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 4000)
        // Camera-style image: landscape pixels, displayed rotated.
        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)

        let prepared = try NotePhotoImageProcessor.preparePhoto(from: uiImage, assetIdentifier: nil)

        let stored = try NotePhotoImageProcessor.downsampledImage(data: prepared.jpegData, maxPixelSize: 10_000)
        #expect(stored.width == 1536)
        #expect(stored.height == 2048)
    }

    // MARK: - Opaque output (JPEG must not get an alpha bitmap)

    private static func hasAlpha(_ image: CGImage) -> Bool {
        ![.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo)
    }

    @Test(arguments: [(4000, 3000), (3000, 4000)])
    func downsample_opaqueJPEG_hasNoAlpha(width: Int, height: Int) throws {
        let data = PhotoTestImages.jpegData(width: width, height: height)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(!Self.hasAlpha(image))
        #expect(image.width == (width > height ? 2048 : 1536))
        #expect(image.height == (width > height ? 1536 : 2048))
    }

    @Test func cameraImage_isOpaque() throws {
        let cgImage = PhotoTestImages.splitColorImage(width: 4000, height: 3000)
        let image = try NotePhotoImageProcessor.downsampledImage(
            from: UIImage(cgImage: cgImage, scale: 1, orientation: .up),
            maxPixelSize: 2048
        )
        #expect(!Self.hasAlpha(image))
        #expect(image.width == 2048)
        #expect(image.height == 1536)
    }

    @Test func cameraImage_upOrientation_keepsPixelLayout() throws {
        let cgImage = PhotoTestImages.splitColorImage(width: 400, height: 200)
        let image = try NotePhotoImageProcessor.downsampledImage(
            from: UIImage(cgImage: cgImage, scale: 1, orientation: .up),
            maxPixelSize: 2048
        )
        let left = PhotoTestImages.pixel(of: image, x: 50, y: 100)
        let right = PhotoTestImages.pixel(of: image, x: 350, y: 100)
        #expect(left.red > 200 && left.blue < 50)
        #expect(right.blue > 200 && right.red < 50)
    }

    @Test func cameraImage_rightOrientation_isRotatedUpright() throws {
        // `.right`: stored landscape, displayed rotated 90° clockwise, so the
        // stored left (red) half ends up on top.
        let cgImage = PhotoTestImages.splitColorImage(width: 400, height: 200)
        let image = try NotePhotoImageProcessor.downsampledImage(
            from: UIImage(cgImage: cgImage, scale: 1, orientation: .right),
            maxPixelSize: 2048
        )
        #expect(image.width == 200)
        #expect(image.height == 400)
        #expect(!Self.hasAlpha(image))
        let top = PhotoTestImages.pixel(of: image, x: 100, y: 50)
        let bottom = PhotoTestImages.pixel(of: image, x: 100, y: 350)
        #expect(top.red > 200 && top.blue < 50)
        #expect(bottom.blue > 200 && bottom.red < 50)
    }

    @Test func exifOrientation6_isRotatedUpright() throws {
        let data = PhotoTestImages.encode(PhotoTestImages.splitColorImage(width: 400, height: 200), type: .jpeg, exifOrientation: 6)
        let image = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(image.width == 200)
        #expect(image.height == 400)
        let top = PhotoTestImages.pixel(of: image, x: 100, y: 50)
        let bottom = PhotoTestImages.pixel(of: image, x: 100, y: 350)
        #expect(top.red > 200 && top.blue < 50)
        #expect(bottom.blue > 200 && bottom.red < 50)
    }

    @Test func opaqueImage_flattensAlphaSource() throws {
        let data = PhotoTestImages.pngWithAlpha(width: 1200, height: 800)
        let decoded = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        #expect(Self.hasAlpha(decoded)) // ImageIO keeps the PNG's alpha channel

        let opaque = try NotePhotoImageProcessor.opaqueImage(decoded)

        #expect(!Self.hasAlpha(opaque))
        #expect(opaque.width == 1200)
        #expect(opaque.height == 800)
        let pixel = PhotoTestImages.pixel(of: opaque, x: 600, y: 400)
        #expect(abs(Int(pixel.red) - 51) <= 3)
        #expect(abs(Int(pixel.green) - 102) <= 3)
        #expect(abs(Int(pixel.blue) - 153) <= 3)
    }

    @Test func opaqueImage_transparentArea_becomesWhite() throws {
        let data = PhotoTestImages.pngWithAlpha(width: 400, height: 400, transparentCorner: true)
        let decoded = try NotePhotoImageProcessor.downsampledImage(data: data, maxPixelSize: 2048)
        let opaque = try NotePhotoImageProcessor.opaqueImage(decoded)
        let corner = PhotoTestImages.pixel(of: opaque, x: 50, y: 50)
        #expect(corner.red > 245 && corner.green > 245 && corner.blue > 245)
    }

    @Test func opaqueImage_opaqueSource_isReturnedAsIs() throws {
        let image = try NotePhotoImageProcessor.downsampledImage(
            data: PhotoTestImages.jpegData(width: 800, height: 600),
            maxPixelSize: 2048
        )
        #expect(try NotePhotoImageProcessor.opaqueImage(image) === image)
    }

    @Test func preparePhoto_fromAlphaPNG_producesValidJPEG() throws {
        let directory = try PhotoTestImages.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try PhotoTestImages.writeTemporaryFile(PhotoTestImages.pngWithAlpha(width: 3000, height: 2000), in: directory)

        let prepared = try NotePhotoImageProcessor.preparePhoto(fromFileAt: url, assetIdentifier: nil)

        let source = try #require(CGImageSourceCreateWithData(prepared.jpegData as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == "public.jpeg")
        let stored = try NotePhotoImageProcessor.downsampledImage(data: prepared.jpegData, maxPixelSize: 10_000)
        #expect(stored.width == 2048)
        #expect(stored.height == 1365)
        #expect(!Self.hasAlpha(stored))
    }
}
