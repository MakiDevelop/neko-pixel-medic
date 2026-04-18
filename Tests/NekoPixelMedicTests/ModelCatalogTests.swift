import Foundation
import XCTest

@testable import NekoPixelMedic

final class ModelCatalogTests: XCTestCase {
    func testBuiltInModelsUseDistinctIDsAndGitHubReleaseAssets() {
        let models = DownloadableModel.builtIn
        let ids = Set(models.map(\.id))

        XCTAssertEqual(ids.count, models.count)

        for model in models {
            XCTAssertTrue(model.sourceURL.absoluteString.contains("github.com"))
            XCTAssertTrue(model.sourceURL.absoluteString.contains("/releases/download/"))
            XCTAssertFalse(model.artifacts.isEmpty)
        }
    }

    func testStoreMarksModelAsInstalledWhenArtifactsExist() throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = ModelStore(baseDirectoryURL: rootDirectory)
        let model = DownloadableModel.builtIn[0]

        defer {
            try? FileManager.default.removeItem(at: rootDirectory)
        }

        let artifact = model.primaryArtifact
        let artifactURL = store.artifactURL(for: artifact, model: model)
        try FileManager.default.createDirectory(
            at: artifactURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try Data("demo".utf8).write(to: artifactURL)

        let item = store.item(for: model)

        XCTAssertEqual(item.installedArtifactCount, 1)
        XCTAssertEqual(item.installedBytes, 4)
        XCTAssertEqual(item.state, .installed)
    }
}
