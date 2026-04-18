import Foundation

struct DownloadableModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let summary: String
    let version: String
    let sourceName: String
    let sourceURL: URL
    let supportedPresets: [RepairPreset]
    let artifacts: [ModelArtifact]

    var primaryArtifact: ModelArtifact {
        artifacts[0]
    }

    var roleSummary: String {
        let names = supportedPresets.map(\.displayName)
        return names.joined(separator: " / ")
    }

    static let builtIn: [DownloadableModel] = [
        DownloadableModel(
            id: "realesr-general-x4v3",
            displayName: "Real-ESRGAN General x4v3",
            summary: "一般照片超解析度的官方小型權重，適合先接 super resolution 真 backend。",
            version: "v0.2.5.0",
            sourceName: "xinntao/Real-ESRGAN",
            sourceURL: URL(string: "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth")!,
            supportedPresets: [.superResolution],
            artifacts: [
                ModelArtifact(
                    fileName: "realesr-general-x4v3.pth",
                    remoteURL: URL(string: "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth")!
                )
            ]
        ),
        DownloadableModel(
            id: "gfpgan-v1.3",
            displayName: "GFPGAN v1.3",
            summary: "官方 face restoration 權重，先作為老照片與人臉修復的第一個真模型入口。",
            version: "v1.3.0",
            sourceName: "TencentARC/GFPGAN",
            sourceURL: URL(string: "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth")!,
            supportedPresets: [.restore],
            artifacts: [
                ModelArtifact(
                    fileName: "GFPGANv1.3.pth",
                    remoteURL: URL(string: "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth")!
                )
            ]
        ),
        DownloadableModel(
            id: "codeformer",
            displayName: "CodeFormer",
            summary: "官方 blind face restoration 權重，之後可接到 restore / deblur 的高品質路徑。",
            version: "v0.1.0",
            sourceName: "sczhou/CodeFormer",
            sourceURL: URL(string: "https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth")!,
            supportedPresets: [.restore, .deblur],
            artifacts: [
                ModelArtifact(
                    fileName: "codeformer.pth",
                    remoteURL: URL(string: "https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth")!
                )
            ]
        )
    ]
}

struct ModelArtifact: Identifiable, Hashable {
    let fileName: String
    let remoteURL: URL

    var id: String { fileName }
}

enum ModelInstallState: Equatable {
    case notInstalled
    case downloading(progress: Double?)
    case installed
    case failed(message: String)
}

struct ModelLibraryItem: Identifiable, Equatable {
    let model: DownloadableModel
    var state: ModelInstallState
    var installedBytes: Int64
    var installedArtifactCount: Int

    var id: String { model.id }

    var actionTitle: String {
        switch state {
        case .notInstalled:
            return "下載"
        case .downloading:
            return "下載中"
        case .installed:
            return "已安裝"
        case .failed:
            return "重試"
        }
    }

    var stateLabel: String {
        switch state {
        case .notInstalled:
            return "未下載"
        case let .downloading(progress):
            guard let progress else {
                return "下載中"
            }
            return "下載中 \(Int(progress * 100))%"
        case .installed:
            return "已安裝"
        case let .failed(message):
            return message
        }
    }

    var detailLine: String {
        if installedArtifactCount > 0 {
            let size = ByteCountFormatter.string(fromByteCount: installedBytes, countStyle: .file)
            return "\(installedArtifactCount) 個檔案 · \(size)"
        }

        return model.sourceName
    }

    var canStartDownload: Bool {
        switch state {
        case .notInstalled, .failed:
            return true
        case .downloading, .installed:
            return false
        }
    }
}
