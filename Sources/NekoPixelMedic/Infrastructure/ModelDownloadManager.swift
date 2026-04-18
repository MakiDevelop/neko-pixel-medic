import Foundation

struct ModelDownloadProgress: Sendable {
    let completedArtifacts: Int
    let totalArtifacts: Int
    let currentArtifactProgress: Double?

    var fractionCompleted: Double? {
        guard totalArtifacts > 0 else {
            return nil
        }

        let completed = Double(completedArtifacts)
        let artifactProgress = currentArtifactProgress ?? 0
        return min((completed + artifactProgress) / Double(totalArtifacts), 1)
    }
}

struct ModelDownloadManager: Sendable {
    func download(
        model: DownloadableModel,
        into store: ModelStore,
        onProgress: @escaping @Sendable (ModelDownloadProgress) -> Void
    ) async throws {
        _ = try store.prepareDirectory(for: model)

        for (index, artifact) in model.artifacts.enumerated() {
            let destinationURL = store.artifactURL(for: artifact, model: model)

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                onProgress(
                    ModelDownloadProgress(
                        completedArtifacts: index + 1,
                        totalArtifacts: model.artifacts.count,
                        currentArtifactProgress: 0
                    )
                )
                continue
            }

            let downloader = ArtifactDownloader(destinationURL: destinationURL)
            try await downloader.download(from: artifact.remoteURL) { progress in
                onProgress(
                    ModelDownloadProgress(
                        completedArtifacts: index,
                        totalArtifacts: model.artifacts.count,
                        currentArtifactProgress: progress
                    )
                )
            }

            onProgress(
                ModelDownloadProgress(
                    completedArtifacts: index + 1,
                    totalArtifacts: model.artifacts.count,
                    currentArtifactProgress: 0
                )
            )
        }
    }
}

private final class ArtifactDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destinationURL: URL
    private var continuation: CheckedContinuation<Void, Error>?
    private var progressHandler: (@Sendable (Double?) -> Void)?
    private var session: URLSession?

    init(destinationURL: URL) {
        self.destinationURL = destinationURL
    }

    func download(
        from remoteURL: URL,
        progressHandler: @escaping @Sendable (Double?) -> Void
    ) async throws {
        self.progressHandler = progressHandler

        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60 * 60

        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.session = session

        defer {
            session.invalidateAndCancel()
            self.session = nil
            self.progressHandler = nil
        }

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.downloadTask(with: remoteURL).resume()
        }
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress: Double?
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = nil
        }

        progressHandler?(progress)
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(at: location, to: destinationURL)
            finish(with: .success(()))
        } catch {
            finish(with: .failure(error))
        }
    }

    func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else {
            return
        }

        finish(with: .failure(error))
    }

    private func finish(with result: Result<Void, Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil

        switch result {
        case .success:
            continuation.resume()
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }
}
