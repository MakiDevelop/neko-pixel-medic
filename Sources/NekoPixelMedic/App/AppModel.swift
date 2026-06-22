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

    // Batch processing support (initial implementation)
    struct BatchItem: Identifiable {
        let id = UUID()
        let photo: ImportedPhoto
        var result: ProcessedPhoto?
        var errorMessage: String?
    }

    var batchQueue: [BatchItem] = []
    var isBatchProcessing = false
    var batchProgress: Double = 0

    // Toggle to experiment with ML stub (real inference not wired yet)
    var useMLBackend: Bool = false {
        didSet {
            statusMessage = useMLBackend 
                ? "使用 MLPhotoRepairService（真實 CoreML 載入中，模型未轉換前會報錯）"
                : "使用 prototype CI backend"
        }
    }

    private let availableModels: [DownloadableModel]
    private let modelStore: ModelStore
    private let modelDownloadManager: ModelDownloadManager
    private let repairService: PhotoRepairService
    private var debounceTask: Task<Void, Never>?
    private var modelDownloadTask: Task<Void, Never>?
    private var renderTask: Task<Void, Never>?
    private var batchTask: Task<Void, Never>?

    private var currentRepairService: PhotoRepairService {
        if useMLBackend {
            return MLPhotoRepairService(modelStore: modelStore)
        }
        return repairService
    }

    init(
        availableModels: [DownloadableModel] = DownloadableModel.builtIn,
        modelStore: ModelStore = ModelStore(),
        modelDownloadManager: ModelDownloadManager = ModelDownloadManager(),
        repairService: PhotoRepairService = PrototypePhotoRepairService()
    ) {
        self.availableModels = availableModels
        self.modelStore = modelStore
        self.modelDownloadManager = modelDownloadManager
        self.repairService = repairService
        refreshModelLibrary()
    }

    // Real ML: inject MLPhotoRepairService(modelStore: ...) when .pth converted to CoreML.
    // Set useMLBackend = true to activate (will error until models ready).

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
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "載入 (可多選加入批次)"

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        let first = panel.urls.first!
        loadPhoto(from: first)

        for url in panel.urls {
            addToBatch(url: url)
        }
    }

    func handleDroppedFiles(_ urls: [URL]) {
        let supported = urls.filter(Self.isSupportedImageURL)
        guard !supported.isEmpty else {
            statusMessage = "拖進來的內容不是支援的圖片格式。"
            return
        }

        // Load first for immediate preview
        loadPhoto(from: supported[0])

        // Add remaining (and first if want) to batch
        for url in supported {
            addToBatch(url: url)
        }
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

        renderTask = Task { [selectedPreset, repairService] in
            do {
                try Task.checkCancellation()

                // Use non-detached Task so parent cancellation can propagate
                let result = try await Task(priority: .userInitiated) {
                    try currentRepairService.processPhoto(at: url, settings: settings)
                }.value

                try Task.checkCancellation()

                processedData = result.previewData
                processedImage = NSImage(data: result.previewData)
                processedPixelSize = result.pixelSize
                renderNotes = result.notes
                isProcessing = false
                statusMessage = "\(selectedPreset.displayName) preview 已更新。"
            } catch is CancellationError {
                // Silently ignore cancellation
                return
            } catch {
                if !Task.isCancelled {
                    isProcessing = false
                    statusMessage = error.localizedDescription
                }
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
                try Task.checkCancellation()

                try await modelDownloadManager.download(model: model, into: modelStore) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.updateModelState(.downloading(progress: progress.fractionCompleted), forModelID: model.id)
                    }
                }

                try Task.checkCancellation()

                refreshModelLibrary()
                activeModelDownloadID = nil
                statusMessage = "已安裝 \(model.displayName)。下一步只剩把推論 backend 接上。"
            } catch is CancellationError {
                return
            } catch {
                if !Task.isCancelled {
                    activeModelDownloadID = nil
                    updateModelState(.failed(message: "下載失敗"), forModelID: model.id)
                    statusMessage = "模型下載失敗：\(error.localizedDescription)"
                }
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
                try Task.checkCancellation()
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

    // MARK: - Batch processing (prototype)

    func addToBatch(url: URL) {
        do {
            let photo = try ImportedPhoto.load(from: url)
            if !batchQueue.contains(where: { $0.photo.url == url }) {
                batchQueue.append(BatchItem(photo: photo))
                statusMessage = "已加入批次：\(photo.shortName)（共 \(batchQueue.count) 張）"
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func clearBatch() {
        batchTask?.cancel()
        batchQueue.removeAll()
        isBatchProcessing = false
        batchProgress = 0
        statusMessage = "批次已清空"
    }

    func processBatch() {
        guard !batchQueue.isEmpty else {
            statusMessage = "批次為空"
            return
        }

        batchTask?.cancel()
        isBatchProcessing = true
        batchProgress = 0
        statusMessage = "開始批次處理 \(batchQueue.count) 張照片..."

        let total = Double(batchQueue.count)
        let currentSettings = RepairSettings(preset: selectedPreset, strength: strength)

        // Capture indices and update in place safely
        batchTask = Task { [currentRepairService] in
            var processedCount = 0

            for index in batchQueue.indices {
                guard !Task.isCancelled else { break }

                let photo = batchQueue[index].photo
                do {
                    let photoURL = photo.url
                    let settings = currentSettings
                    let result = try await Task(priority: .userInitiated) {
                        try currentRepairService.processPhoto(at: photoURL, settings: settings)
                    }.value

                    await MainActor.run {
                        batchQueue[index].result = result
                        batchQueue[index].errorMessage = nil
                    }
                } catch {
                    await MainActor.run {
                        batchQueue[index].errorMessage = error.localizedDescription
                        batchQueue[index].result = nil
                    }
                }

                processedCount += 1
                let progress = Double(processedCount) / total
                await MainActor.run {
                    batchProgress = progress
                    statusMessage = "批次處理中：\(processedCount)/\(batchQueue.count)"
                }
            }

            await MainActor.run {
                isBatchProcessing = false
                batchProgress = 1.0
                statusMessage = "批次完成 \(processedCount)/\(batchQueue.count) 張"
            }
        }
    }
}
