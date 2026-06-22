import Foundation

/// Stub for future real ML-based repair using downloaded models (after .pth → CoreML conversion).
/// 
/// Real-ESRGAN, GFPGAN, CodeFormer etc. require:
/// 1. Convert .pth weights to .mlmodel / .mlpackage using coremltools + custom layers if needed.
/// 2. Load via MLModel or VNCoreMLModel.
/// 3. Run inference with proper pre/post processing (normalization, tiling for large images, etc.).
///
/// For now, this is a placeholder that can delegate to prototype or fail explicitly
/// until real models are wired.
struct MLPhotoRepairService: PhotoRepairService {
    private let fallback: PhotoRepairService

    init(fallback: PhotoRepairService = PrototypePhotoRepairService()) {
        self.fallback = fallback
    }

    func processPhoto(at url: URL, settings: RepairSettings) throws -> ProcessedPhoto {
        // TODO: Check modelStore for installed CoreML models matching the preset.
        // If available (e.g. for .superResolution use Real-ESRGAN converted model):
        //   - Load MLModel
        //   - Prepare input (resize, normalize to model's expected format)
        //   - Run prediction
        //   - Post-process (denorm, etc.)
        //
        // Example future:
        // guard let model = try? loadCoreMLModel(for: settings.preset) else {
        //     throw PhotoRepairError.renderFailed
        // }
        // ... inference ...

        // Current stub: explicitly indicate not ready, or fallback for development
        // To keep UI working during development, we fallback (remove this for strict mode)
        // print("[MLPhotoRepairService] Real ML inference not yet implemented. Falling back to prototype.")
        return try fallback.processPhoto(at: url, settings: settings)

        // Alternative strict stub:
        // throw PhotoRepairError.renderFailed  // "Real ML backend not wired yet"
    }

    // Placeholder for future model loading
    private func loadCoreMLModel(for preset: RepairPreset) throws -> Any {
        // TODO: Use modelStore to find converted .mlmodelc or compiled model
        // e.g. for "realesr-general-x4v3" look for the converted version
        throw PhotoRepairError.renderFailed
    }
}