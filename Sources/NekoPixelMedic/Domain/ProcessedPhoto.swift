import CoreGraphics
import Foundation

struct ProcessedPhoto: Equatable {
    let previewData: Data
    let pixelSize: CGSize
    let notes: [String]
}
