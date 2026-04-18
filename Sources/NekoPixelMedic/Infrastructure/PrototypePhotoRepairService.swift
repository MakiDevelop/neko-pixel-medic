import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PrototypePhotoRepairService {
    func processPhoto(at url: URL, settings: RepairSettings) throws -> ProcessedPhoto {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            throw PhotoRepairError.unsupportedFile(url)
        }

        let context = CIContext()
        let plan = settings.preset.makePlan(strength: settings.strength)
        let processedImage = plan.passes.reduce(CIImage(cgImage: cgImage)) { image, pass in
            apply(pass, to: image)
        }

        let renderExtent = processedImage.extent.integral
        guard let outputCGImage = context.createCGImage(processedImage, from: renderExtent) else {
            throw PhotoRepairError.renderFailed
        }

        return ProcessedPhoto(
            previewData: try encodePNG(outputCGImage),
            pixelSize: CGSize(width: outputCGImage.width, height: outputCGImage.height),
            notes: plan.notes
        )
    }

    private func apply(_ pass: RepairPass, to image: CIImage) -> CIImage {
        switch pass {
        case let .noiseReduction(noiseLevel, sharpness):
            guard let filter = CIFilter(name: "CINoiseReduction") else {
                return image
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(noiseLevel, forKey: "inputNoiseLevel")
            filter.setValue(sharpness, forKey: "inputSharpness")
            return filter.outputImage ?? image

        case let .sharpen(amount):
            guard let filter = CIFilter(name: "CISharpenLuminance") else {
                return image
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(amount, forKey: "inputSharpness")
            return filter.outputImage ?? image

        case let .tone(saturation, contrast, brightness, highlight, shadow):
            guard let toneFilter = CIFilter(name: "CIColorControls"),
                  let lightFilter = CIFilter(name: "CIHighlightShadowAdjust")
            else {
                return image
            }

            toneFilter.setValue(image, forKey: kCIInputImageKey)
            toneFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            toneFilter.setValue(contrast, forKey: kCIInputContrastKey)
            toneFilter.setValue(brightness, forKey: kCIInputBrightnessKey)

            let toned = toneFilter.outputImage ?? image

            lightFilter.setValue(toned, forKey: kCIInputImageKey)
            lightFilter.setValue(highlight, forKey: "inputHighlightAmount")
            lightFilter.setValue(shadow, forKey: "inputShadowAmount")
            return lightFilter.outputImage ?? toned

        case let .vibrance(amount):
            guard let filter = CIFilter(name: "CIVibrance") else {
                return image
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(amount, forKey: "inputAmount")
            return filter.outputImage ?? image

        case let .upscale(factor):
            guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
                return image
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(factor, forKey: kCIInputScaleKey)
            filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            return filter.outputImage ?? image
        }
    }

    private func encodePNG(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoRepairError.encodeFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw PhotoRepairError.encodeFailed
        }

        return data as Data
    }
}

enum PhotoRepairError: LocalizedError {
    case unsupportedFile(URL)
    case renderFailed
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case let .unsupportedFile(url):
            return "不支援這個檔案：\(url.lastPathComponent)"
        case .renderFailed:
            return "產生修復 preview 失敗。"
        case .encodeFailed:
            return "輸出 PNG 失敗。"
        }
    }
}
