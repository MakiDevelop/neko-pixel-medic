import Foundation

struct ModelStore: Sendable {
    let baseDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil
    ) {
        self.baseDirectoryURL = baseDirectoryURL ?? Self.makeDefaultBaseDirectoryURL(fileManager: fileManager)
    }

    func item(for model: DownloadableModel, state: ModelInstallState = .notInstalled) -> ModelLibraryItem {
        let installedURLs = model.artifacts.map { artifactURL(for: $0, model: model) }
        let existingURLs = installedURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
        let installedBytes = existingURLs.reduce(into: Int64(0)) { partialResult, url in
            partialResult += fileSize(at: url)
        }

        let resolvedState: ModelInstallState = existingURLs.count == model.artifacts.count ? .installed : state

        return ModelLibraryItem(
            model: model,
            state: resolvedState,
            installedBytes: installedBytes,
            installedArtifactCount: existingURLs.count
        )
    }

    func items(for models: [DownloadableModel]) -> [ModelLibraryItem] {
        models.map { item(for: $0) }
    }

    func prepareDirectory(for model: DownloadableModel) throws -> URL {
        let directory = installDirectory(for: model)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory
    }

    func installDirectory(for model: DownloadableModel) -> URL {
        baseDirectoryURL
            .appendingPathComponent(model.id, isDirectory: true)
            .appendingPathComponent(model.version, isDirectory: true)
    }

    func artifactURL(for artifact: ModelArtifact, model: DownloadableModel) -> URL {
        installDirectory(for: model)
            .appendingPathComponent(artifact.fileName, isDirectory: false)
    }

    func revealRootDirectory() throws -> URL {
        try FileManager.default.createDirectory(at: baseDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        return baseDirectoryURL
    }

    private func fileSize(at url: URL) -> Int64 {
        let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return size.map(Int64.init) ?? 0
    }

    private static func makeDefaultBaseDirectoryURL(fileManager: FileManager) -> URL {
        let applicationSupport = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        return applicationSupport
            .appendingPathComponent("NekoPixelMedic", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }
}
