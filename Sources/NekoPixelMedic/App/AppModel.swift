import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppModel {
    var importedPhoto: ImportedPhoto?
    var processedImage: NSImage?
    var processedData: Data?
    var processedPixelSize: CGSize?
    var renderNotes: [String] = []
    var modelLibrary: [ModelLibraryItem] = []
    var selectedPreset: RepairPreset = .restore
    var strength: Double = 0.68
    var isProcessing = false
    var activeModelDownloadID: String?
    var statusMessage = "拖一張受傷照片進來，先把第一版 prototype 跑起來。"
    var lastExportURL: URL?

    private let availableModels: [DownloadableModel]
    private let modelStore: ModelStore
    private let modelDownloadManager: ModelDownloadManager
    private var debounceTask: Task<Void, Never>?
    private var modelDownloadTask: Task<Void, Never>?
    private var renderTask: Task<Void, Never>?

    init(
        availableModels: [DownloadableModel] = DownloadableModel.builtIn,
        modelStore: ModelStore = ModelStore(),
        modelDownloadManager: ModelDownloadManager = ModelDownloadManager()
    ) {
        self.availableModels = availableModels
        self.modelStore = modelStore
        self.modelDownloadManager = modelDownloadManager
        refreshModelLibrary()
    }

    var originalImage: NSImage? {
        importedPhoto?.previewImage
    }

    var currentPlan: RepairPlan {
        selectedPreset.makePlan(strength: strength)
    }

    var recommendedPresets: [RepairPreset] {
        importedPhoto?.recommendedPresets ?? [.restore, .deblur, .denoise]
    }

    var canExport: Bool {
        processedData != nil
    }

    var installedModelCount: Int {
        modelLibrary.filter { item in
            if case .installed = item.state {
                return true
            }
            return false
        }.count
    }

    func importPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "載入"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        loadPhoto(from: url)
    }

    func handleDroppedFiles(_ urls: [URL]) {
        guard let firstSupportedImage = urls.first(where: Self.isSupportedImageURL) else {
            statusMessage = "拖進來的內容不是支援的圖片格式。"
            return
        }

        loadPhoto(from: firstSupportedImage)
    }

    func selectPreset(_ preset: RepairPreset) {
        selectedPreset = preset
        schedulePreviewRefresh()
    }

    func updateStrength(_ value: Double) {
        strength = value
        schedulePreviewRefresh()
    }

    func refreshPreview() {
        guard let importedPhoto else {
            statusMessage = "先載入一張照片再產生 preview。"
            return
        }

        debounceTask?.cancel()
        renderTask?.cancel()
        isProcessing = true
        statusMessage = "正在套用 \(selectedPreset.displayName)…"

        let url = importedPhoto.url
        let settings = RepairSettings(preset: selectedPreset, strength: strength)

        renderTask = Task { [selectedPreset] in
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try PrototypePhotoRepairService().processPhoto(at: url, settings: settings)
                }.value

                guard !Task.isCancelled else {
                    return
                }

                processedData = result.previewData
                processedImage = NSImage(data: result.previewData)
                processedPixelSize = result.pixelSize
                renderNotes = result.notes
                isProcessing = false
                statusMessage = "\(selectedPreset.displayName) preview 已更新。"
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                isProcessing = false
                statusMessage = error.localizedDescription
            }
        }
    }

    func exportPreview() {
        guard let processedData, let importedPhoto else {
            statusMessage = "目前沒有可輸出的 preview。"
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = defaultExportName(for: importedPhoto.url)
        panel.prompt = "輸出 PNG"

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return
        }

        do {
            try processedData.write(to: destinationURL, options: .atomic)
            lastExportURL = destinationURL
            statusMessage = "已輸出到 \(destinationURL.lastPathComponent)。"
        } catch {
            statusMessage = "輸出失敗：\(error.localizedDescription)"
        }
    }

    func revealImportedPhoto() {
        guard let url = importedPhoto?.url else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func revealLastExport() {
        guard let url = lastExportURL else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func downloadModel(_ model: DownloadableModel) {
        guard activeModelDownloadID == nil else {
            statusMessage = "目前已有模型在下載，先等這一個完成。"
            return
        }

        activeModelDownloadID = model.id
        updateModelState(.downloading(progress: 0), forModelID: model.id)
        statusMessage = "正在下載 \(model.displayName)…"

        modelDownloadTask?.cancel()
        modelDownloadTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await modelDownloadManager.download(model: model, into: modelStore) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.updateModelState(.downloading(progress: progress.fractionCompleted), forModelID: model.id)
                    }
                }

                guard !Task.isCancelled else {
                    return
                }

                refreshModelLibrary()
                activeModelDownloadID = nil
                statusMessage = "已安裝 \(model.displayName)。下一步只剩把推論 backend 接上。"
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                activeModelDownloadID = nil
                updateModelState(.failed(message: "下載失敗"), forModelID: model.id)
                statusMessage = "模型下載失敗：\(error.localizedDescription)"
            }
        }
    }

    func revealModelLibraryFolder() {
        do {
            let rootURL = try modelStore.revealRootDirectory()
            NSWorkspace.shared.activateFileViewerSelecting([rootURL])
        } catch {
            statusMessage = "無法打開模型資料夾：\(error.localizedDescription)"
        }
    }

    private func loadPhoto(from url: URL) {
        do {
            let photo = try ImportedPhoto.load(from: url)
            importedPhoto = photo
            processedImage = photo.previewImage
            processedData = nil
            processedPixelSize = nil
            renderNotes = []
            lastExportURL = nil
            statusMessage = "已載入 \(photo.shortName)，開始建立 prototype preview。"
            refreshPreview()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func schedulePreviewRefresh() {
        debounceTask?.cancel()

        guard importedPhoto != nil else {
            return
        }

        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else {
                    return
                }
                self?.refreshPreview()
            } catch {
                return
            }
        }
    }

    private func defaultExportName(for sourceURL: URL) -> String {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        return "\(baseName)-\(selectedPreset.rawValue).png"
    }

    private func refreshModelLibrary() {
        let previousStates = Dictionary(uniqueKeysWithValues: modelLibrary.map { ($0.id, $0.state) })
        modelLibrary = availableModels.map { model in
            modelStore.item(for: model, state: previousStates[model.id] ?? .notInstalled)
        }
    }

    private func updateModelState(_ state: ModelInstallState, forModelID id: String) {
        guard let index = modelLibrary.firstIndex(where: { $0.id == id }) else {
            refreshModelLibrary()
            return
        }

        modelLibrary[index].state = state
    }

    private static func isSupportedImageURL(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey]) else {
            return false
        }

        guard values.isDirectory != true else {
            return false
        }

        return values.contentType?.conforms(to: .image) == true
    }
}
