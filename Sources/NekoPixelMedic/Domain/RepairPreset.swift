import Foundation

enum RepairPreset: String, CaseIterable, Identifiable, Hashable {
    case deblur
    case denoise
    case restore
    case superResolution

    var id: Self { self }

    var displayName: String {
        switch self {
        case .deblur:
            return "去模糊"
        case .denoise:
            return "降噪"
        case .restore:
            return "老照片修復"
        case .superResolution:
            return "超解析度"
        }
    }

    var shortDescription: String {
        switch self {
        case .deblur:
            return "以 sharpen + light denoise 做第一版清晰度補強。"
        case .denoise:
            return "壓低高 ISO / 壓縮雜訊，再補少量細節。"
        case .restore:
            return "先做色調、對比與陰影回補，救回泛黃老照片。"
        case .superResolution:
            return "先用 Lanczos 2x 放大當 baseline，之後再換 Real-ESRGAN。"
        }
    }

    var systemImage: String {
        switch self {
        case .deblur:
            return "camera.aperture"
        case .denoise:
            return "waveform.path.ecg.rectangle"
        case .restore:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .superResolution:
            return "arrow.up.right.and.arrow.down.left.rectangle"
        }
    }

    func makePlan(strength: Double) -> RepairPlan {
        let tuned = min(max(strength, 0), 1)

        switch self {
        case .deblur:
            return RepairPlan(
                headline: "Motion blur rescue",
                notes: [
                    "先用低量降噪壓掉 sharpen 會放大的雜訊。",
                    "主體是 luminance sharpen，強度會跟 slider 一起提高。",
                    "這版是 Core Image prototype，之後再換真正的 deblur model。"
                ],
                passes: [
                    .noiseReduction(noiseLevel: 0.012 + tuned * 0.018, sharpness: 0.25 + tuned * 0.2),
                    .sharpen(amount: 0.32 + tuned * 0.82)
                ],
                outputScale: 1
            )

        case .denoise:
            return RepairPlan(
                headline: "Noise cleanup",
                notes: [
                    "先拉高 noise reduction，再補回一點微細節。",
                    "適合夜拍、老手機 JPEG、或被壓縮過的檔案。",
                    "如果照片本來就偏柔，建議 strength 不要超過 0.75。"
                ],
                passes: [
                    .noiseReduction(noiseLevel: 0.03 + tuned * 0.08, sharpness: 0.42 + tuned * 0.28),
                    .vibrance(amount: 0.06 + tuned * 0.12)
                ],
                outputScale: 1
            )

        case .restore:
            return RepairPlan(
                headline: "Old photo revival",
                notes: [
                    "先回補對比與陰影，再輕微提升飽和度。",
                    "這條管線是為了讓老照片先回到可看的 baseline。",
                    "真實刮痕修復與局部人臉修復下一階段再接 Core ML。"
                ],
                passes: [
                    .tone(
                        saturation: 1.02 + tuned * 0.16,
                        contrast: 1.08 + tuned * 0.22,
                        brightness: 0.01 + tuned * 0.02,
                        highlight: 0.65,
                        shadow: 0.34 + tuned * 0.18
                    ),
                    .vibrance(amount: 0.18 + tuned * 0.26),
                    .sharpen(amount: 0.16 + tuned * 0.22)
                ],
                outputScale: 1
            )

        case .superResolution:
            return RepairPlan(
                headline: "2x prototype upscale",
                notes: [
                    "目前先用 Lanczos 2x 當 preview，讓 UI 與輸出流程先跑起來。",
                    "放大前會先做一點點降噪，避免插值把雜點一起放大。",
                    "後續直接把這條 plan 換成 Real-ESRGAN / Core ML backend。"
                ],
                passes: [
                    .noiseReduction(noiseLevel: 0.014 + tuned * 0.012, sharpness: 0.18 + tuned * 0.18),
                    .upscale(factor: 2),
                    .sharpen(amount: 0.18 + tuned * 0.34)
                ],
                outputScale: 2
            )
        }
    }
}

struct RepairPlan: Equatable {
    let headline: String
    let notes: [String]
    let passes: [RepairPass]
    let outputScale: Double
}

enum RepairPass: Equatable {
    case noiseReduction(noiseLevel: Double, sharpness: Double)
    case sharpen(amount: Double)
    case tone(saturation: Double, contrast: Double, brightness: Double, highlight: Double, shadow: Double)
    case vibrance(amount: Double)
    case upscale(factor: Double)
}
