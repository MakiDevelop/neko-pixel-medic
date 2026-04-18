import SwiftUI

@main
struct NekoPixelMedicApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup("NekoPixelMedic") {
            ContentView(model: model)
                .frame(minWidth: 1220, minHeight: 820)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
