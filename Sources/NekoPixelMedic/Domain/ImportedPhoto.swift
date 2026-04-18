import AppKit
import CoreGraphics
import Foundation
import ImageIO

struct ImportedPhoto {
    let url: URL
    let previewImage: NSImage
    let pixelSize: CGSize
    let fileSizeBytes: Int64

    var shortName: String {
        url.lastPathComponent
    }

    var readableDimensions: String {
        "\(Int(pixelSize.width)) × \(Int(pixelSize.height)) px"
    }

    var readableFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    var readableMegapixels: String {
        let megapixels = (pixelSize.width * pixelSize.height) / 1_000_000
        return String(format: "%.1f MP", megapixels)
    }

    var recommendedPresets: [RepairPreset] {
        var result: [RepairPreset] = [.restore]

        if min(pixelSize.width, pixelSize.height) < 1_600 {
            result.insert(.superResolution, at: 0)
        }

        if max(pixelSize.width, pixelSize.height) >= 2_400 {
            result.insert(.deblur, at: 0)
        }

        if fileSizeBytes < 900_000 {
            result.append(.denoise)
        }

        return Self.unique(result)
    }

    static func load(from url: URL) throws -> ImportedPhoto {
        guard let previewImage = NSImage(contentsOf: url) else {
            throw ImportedPhotoError.unreadableImage(url)
        }

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        else {
            throw ImportedPhotoError.unreadableMetadata(url)
        }

        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? Double(previewImage.size.width)
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? Double(previewImage.size.height)
        let fileSizeBytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0

        return ImportedPhoto(
            url: url,
            previewImage: previewImage,
            pixelSize: CGSize(width: width, height: height),
            fileSizeBytes: fileSizeBytes
        )
    }

    private static func unique(_ presets: [RepairPreset]) -> [RepairPreset] {
        var seen = Set<RepairPreset>()
        return presets.filter { seen.insert($0).inserted }
    }
}

enum ImportedPhotoError: LocalizedError {
    case unreadableImage(URL)
    case unreadableMetadata(URL)

    var errorDescription: String? {
        switch self {
        case let .unreadableImage(url):
            return "無法讀取圖片：\(url.lastPathComponent)"
        case let .unreadableMetadata(url):
            return "讀不到圖片資訊：\(url.lastPathComponent)"
        }
    }
}
