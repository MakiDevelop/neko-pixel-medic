import CoreML
import Foundation
import Vision

/// Stub for future real ML-based repair using downloaded models (after .pth → CoreML conversion).
/// 
/// Real-ESRGAN, GFPGAN, CodeFormer etc. require:
/// 1. Convert .pth weights to .mlmodel / .mlpackage using coremltools + custom layers if needed.
/// 2. Load via MLModel or VNCoreMLModel.
/// 3. Run inference with proper pre/post processing (normalization, tiling for large images, etc.).
///
/// This version throws real errors instead of falling back. Loading logic started here.
struct MLPhotoRepairService: PhotoRepairService {
    private let modelStore: ModelStore?

    init(modelStore: ModelStore? = nil) {
        self.modelStore = modelStore
    }

    func processPhoto(at url: URL, settings: RepairSettings) throws -> ProcessedPhoto {
        // Start of actual CoreML loading
        let vnModel = try loadCoreMLModel(for: settings.preset)

        // TODO: Implement real inference here
        // - Load CGImage from url
        // - Preprocess for the specific model (e.g. Real-ESRGAN expects certain tensor)
        // - Use VNCoreMLRequest(model: vnModel) or direct prediction
        // - Post-process the output feature
        // For now, throw to indicate wiring in progress
        throw PhotoRepairError.mlModelNotReady("Core ML 模型已載入，但完整推論實作尚未完成（需根據模型類型實作前處理/後處理）。")
    }

    private func loadCoreMLModel(for preset: RepairPreset) throws -> VNCoreMLModel {
        // Try to find converted CoreML model in the model store directory
        // Convention: look for .mlmodelc or compiled model in install dir
        guard let store = modelStore else {
            throw PhotoRepairError.mlModelNotReady("ModelStore 未提供，無法定位轉換後的模型。")
        }

        // Map preset to expected model id (from ModelCatalog)
        let modelID: String
        switch preset {
        case .superResolution:
            modelID = "realesr-general-x4v3"
        case .restore, .deblur:
            modelID = "gfpgan-v1.3"  // or codeformer
        case .denoise:
            modelID = "gfpgan-v1.3" // placeholder
        }

        let dir = store.installDirectory(for: DownloadableModel.builtIn.first { $0.id == modelID } ?? DownloadableModel.builtIn[0])

        // Look for compiled .mlmodelc
        let compiledURL = dir.appendingPathComponent("model.mlmodelc")
        let packageURL = dir.appendingPathComponent("model.mlpackage")

        let modelURL: URL
        if FileManager.default.fileExists(atPath: compiledURL.path) {
            modelURL = compiledURL
        } else if FileManager.default.fileExists(atPath: packageURL.path) {
            // Compile on the fly if .mlpackage present
            modelURL = try MLModel.compileModel(at: packageURL)
        } else {
            // Fallback: check for any .mlmodelc in dir
            if let found = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "mlmodelc" || $0.lastPathComponent.hasSuffix(".mlmodelc") }) {
                modelURL = found
            } else {
                throw PhotoRepairError.mlModelNotReady("在 \(dir.path) 找不到轉換後的 Core ML 模型。")
            }
        }

        let ml = try MLModel(contentsOf: modelURL)
        return try VNCoreMLModel(for: ml)
    }
}