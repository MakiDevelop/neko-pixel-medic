import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel

    @State private var isDropTargeted = false
    private let topContentInset: CGFloat = 44

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AmbientBackdrop()

                HStack(alignment: .top, spacing: 20) {
                    leftRail
                        .frame(width: 330)
                        .frame(maxHeight: .infinity, alignment: .top)

                    mainWorkspace
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.horizontal, 24)
                .padding(.top, topContentInset)
                .padding(.bottom, 24)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            }
        }
        .dropDestination(for: URL.self) { items, location in
            handleDrop(items: items, location: location)
        } isTargeted: { isTargeted in
            self.isDropTargeted = isTargeted
        }
        .overlay {
            if isDropTargeted {
                DropTargetOverlay()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: isDropTargeted)
    }

    private var leftRail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                presetShelf
                strengthCard
                modelLibraryCard
                roadmapCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
    }

    private var mainWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                workspaceHeader
                previewSection
                diagnosticsSection
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var heroCard: some View {
        GlassPanel(tint: Color(red: 0.96, green: 0.55, blue: 0.33).opacity(0.34), cornerRadius: 34) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color(red: 0.99, green: 0.62, blue: 0.37).opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("NekoPixelMedic")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("On-device Photo Repair Studio")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }

                Text("先做一個能跑、能看、能輸出的 macOS prototype。這版先用 Core Image 把照片修復工作台搭起來，後面再逐步換成真正的 Core ML / 開源模型 backend。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    ActionPill(title: "匯入照片", systemImage: "plus.viewfinder", style: .primary, action: model.importPhoto)
                    ActionPill(title: "看原圖", systemImage: "folder", style: .secondary, action: model.revealImportedPhoto, isDisabled: model.importedPhoto == nil)
                }
            }
        }
    }

    private var presetShelf: some View {
        GlassPanel(tint: Color.white.opacity(0.14), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Repair Modes",
                    title: "先做四條 prototype 管線",
                    subtitle: "這些 preset 已經會真的產生 preview，不是靜態假畫面。"
                )

                ForEach(RepairPreset.allCases) { preset in
                    Button {
                        model.selectPreset(preset)
                    } label: {
                        PresetCard(
                            preset: preset,
                            isSelected: preset == model.selectedPreset,
                            isRecommended: model.recommendedPresets.contains(preset)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var strengthCard: some View {
        GlassPanel(tint: Color(red: 0.22, green: 0.68, blue: 0.62).opacity(0.24), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    eyebrow: "Tuning",
                    title: "修復強度",
                    subtitle: "Slider 會 debounce 後自動更新 preview。"
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(model.currentPlan.headline)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(model.strength * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }

                    Slider(
                        value: Binding(
                            get: { model.strength },
                            set: { model.updateStrength($0) }
                        ),
                        in: 0.2...1
                    )
                    .tint(Color(red: 0.17, green: 0.78, blue: 0.68))

                    Text(model.selectedPreset.shortDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                ActionPill(
                    title: "重新產生 Preview",
                    systemImage: "sparkles.rectangle.stack",
                    style: .secondary,
                    action: model.refreshPreview,
                    isDisabled: model.importedPhoto == nil
                )
            }
        }
    }

    private var roadmapCard: some View {
        GlassPanel(tint: Color(red: 0.48, green: 0.58, blue: 0.96).opacity(0.22), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    eyebrow: "Roadmap",
                    title: "下一階段直接往真實模型換",
                    subtitle: "UI 和輸出流程先穩住，之後替換 backend 成本會低很多。"
                )

                RoadmapRow(title: "Face Restoration", detail: "GFPGAN / CodeFormer + 局部人臉區域處理")
                RoadmapRow(title: "Batch Queue", detail: "多張照片排程、失敗重試、背景處理")
                RoadmapRow(title: "Model Downloads", detail: "第一版 manifest / store / downloader 已接上，下一步把推論 backend 換過去")
            }
        }
    }

    private var modelLibraryCard: some View {
        GlassPanel(tint: Color(red: 0.83, green: 0.68, blue: 0.22).opacity(0.22), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    eyebrow: "Models",
                    title: "模型下載器",
                    subtitle: "先把權重下載、落地路徑、安裝狀態做起來。這一輪先不直接切推論。"
                )

                HStack(spacing: 10) {
                    StatusBadge(title: "\(model.installedModelCount)/\(model.modelLibrary.count) 已安裝", tint: .white)
                    ActionPill(
                        title: "打開模型資料夾",
                        systemImage: "folder",
                        style: .secondary,
                        action: model.revealModelLibraryFolder
                    )
                }

                ForEach(model.modelLibrary) { item in
                    ModelLibraryRow(
                        item: item,
                        hasActiveDownload: model.activeModelDownloadID != nil,
                        action: { model.downloadModel(item.model) }
                    )
                }
            }
        }
    }

    private var workspaceHeader: some View {
        GlassPanel(tint: Color.white.opacity(0.12), cornerRadius: 34) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("受傷照片工作台")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("匯入一張照片，立刻在右邊看到 prototype 修復結果。先把人機互動、檔案流、輸出路徑做紮實，再接上真正的模型推論。")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 10) {
                        StatusBadge(title: model.statusMessage, tint: model.isProcessing ? .orange : .white)

                        HStack(spacing: 10) {
                            ActionPill(title: "輸出 PNG", systemImage: "square.and.arrow.up", style: .primary, action: model.exportPreview, isDisabled: !model.canExport)
                            ActionPill(title: "看輸出", systemImage: "folder", style: .secondary, action: model.revealLastExport, isDisabled: model.lastExportURL == nil)
                        }
                    }
                }

                if let importedPhoto = model.importedPhoto {
                    HStack(spacing: 12) {
                        StatTile(title: "來源檔", value: importedPhoto.shortName, tint: .white.opacity(0.92))
                        StatTile(title: "尺寸", value: importedPhoto.readableDimensions, tint: .orange)
                        StatTile(title: "像素量", value: importedPhoto.readableMegapixels, tint: .cyan)
                        StatTile(title: "大小", value: importedPhoto.readableFileSize, tint: .green)
                    }
                }
            }
        }
    }

    private var previewSection: some View {
        GlassPanel(tint: Color(red: 0.95, green: 0.75, blue: 0.48).opacity(0.18), cornerRadius: 34) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(
                    eyebrow: "Preview",
                    title: "原圖 vs 修復結果",
                    subtitle: "現在已經是可操作的 baseline：匯入、預覽、輸出都會真的動。"
                )

                if model.importedPhoto == nil {
                    EmptyPreviewState(importAction: model.importPhoto)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) {
                            imagePane(title: "Original", image: model.originalImage, subtitle: model.importedPhoto?.readableDimensions ?? "尚未載入", accent: .white.opacity(0.9))
                            imagePane(title: "Prototype Output", image: model.processedImage, subtitle: outputSubtitle, accent: Color(red: 0.22, green: 0.74, blue: 0.68))
                        }

                        VStack(spacing: 16) {
                            imagePane(title: "Original", image: model.originalImage, subtitle: model.importedPhoto?.readableDimensions ?? "尚未載入", accent: .white.opacity(0.9))
                            imagePane(title: "Prototype Output", image: model.processedImage, subtitle: outputSubtitle, accent: Color(red: 0.22, green: 0.74, blue: 0.68))
                        }
                    }
                }
            }
        }
    }

    private var diagnosticsSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                diagnosisCard
                pipelineCard
            }

            VStack(alignment: .leading, spacing: 20) {
                diagnosisCard
                pipelineCard
            }
        }
    }

    private var diagnosisCard: some View {
        GlassPanel(tint: Color(red: 0.3, green: 0.44, blue: 0.92).opacity(0.22), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Diagnosis",
                    title: "第一輪建議",
                    subtitle: "先根據解析度與檔案大小給出合理的起手式。"
                )

                if model.importedPhoto == nil {
                    Text("載入圖片後，這裡會顯示起手式建議。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.recommendedPresets) { preset in
                        HStack(spacing: 10) {
                            Image(systemName: preset.systemImage)
                                .foregroundStyle(.white)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.displayName)
                                    .font(.headline)
                                Text(preset.shortDescription)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Text("推薦")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.16), in: Capsule())
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var pipelineCard: some View {
        GlassPanel(tint: Color(red: 0.14, green: 0.74, blue: 0.7).opacity(0.2), cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Pipeline",
                    title: model.currentPlan.headline,
                    subtitle: "目前這版是可替換式 backend。等模型 ready，只要把 pass 實作換掉。"
                )

                ForEach(Array(model.currentPlan.notes.enumerated()), id: \.offset) { index, note in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.18), in: Circle())
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let exportURL = model.lastExportURL {
                    Label("最近輸出：\(exportURL.lastPathComponent)", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func imagePane(title: String, image: NSImage?, subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.18), in: Capsule())
            }

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.2))

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        if model.isProcessing {
                            ProgressView()
                                .controlSize(.large)
                        }
                        Label("等待 preview", systemImage: "sparkles")
                            .font(.headline)
                        Text("切換 preset 或 strength 後會重新產生。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 420)
            .overlay(alignment: .topLeading) {
                if model.isProcessing && title == "Prototype Output" {
                    StatusBadge(title: "Rendering…", tint: .orange)
                        .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var outputSubtitle: String {
        guard let processedPixelSize = model.processedPixelSize else {
            return model.isProcessing ? "正在更新…" : "尚未輸出"
        }

        return "\(Int(processedPixelSize.width)) × \(Int(processedPixelSize.height)) px"
    }

    private func handleDrop(items: [URL], location _: CGPoint) -> Bool {
        model.handleDroppedFiles(items)
        return true
    }
}

private struct GlassPanel<Content: View>: View {
    let tint: Color
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
    }
}

private struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PresetCard: View {
    let preset: RepairPreset
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: preset.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(preset.displayName)
                        .font(.headline)
                    if isRecommended {
                        Text("推薦")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
                Text(preset.shortDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.14) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(isSelected ? Color.white.opacity(0.26) : Color.clear, lineWidth: 1)
                )
        )
    }
}

private struct ActionPill: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.62, blue: 0.37),
                        Color(red: 0.91, green: 0.43, blue: 0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(Color.white.opacity(0.12))
        }
    }
}

private struct StatusBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.16), in: Capsule())
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct RoadmapRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ModelLibraryRow: View {
    let item: ModelLibraryItem
    let hasActiveDownload: Bool
    let action: () -> Void

    private var actionDisabled: Bool {
        if !item.canStartDownload {
            return true
        }

        return hasActiveDownload
    }

    private var stateTint: Color {
        switch item.state {
        case .notInstalled:
            return .white
        case .downloading:
            return .orange
        case .installed:
            return .green
        case .failed:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.model.displayName)
                        .font(.headline)
                    Text(item.model.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ActionPill(
                    title: item.actionTitle,
                    systemImage: item.canStartDownload ? "arrow.down.circle" : "checkmark.circle",
                    style: item.canStartDownload ? .primary : .secondary,
                    action: action,
                    isDisabled: actionDisabled
                )
            }

            HStack(spacing: 8) {
                StatusBadge(title: item.stateLabel, tint: stateTint)
                Text(item.model.roleSummary)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }

            if case let .downloading(progress) = item.state {
                ProgressView(value: progress ?? 0)
                    .progressViewStyle(.linear)
                    .tint(.orange)
            }

            Text(item.detailLine)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Label(item.model.sourceName, systemImage: "shippingbox")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct EmptyPreviewState: View {
    let importAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))

            Text("拖圖片進來，或先手動選一張")
                .font(.title3.weight(.semibold))

            Text("支援一般圖片格式。匯入後會自動跑第一輪 prototype 修復，右邊直接看到結果。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 480)

            ActionPill(title: "選擇照片", systemImage: "plus.viewfinder", style: .primary, action: importAction)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 10]))
                .foregroundStyle(Color.white.opacity(0.18))
        )
    }
}

private struct AmbientBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.1, blue: 0.16),
                    Color(red: 0.09, green: 0.14, blue: 0.19),
                    Color(red: 0.18, green: 0.12, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.99, green: 0.62, blue: 0.37).opacity(0.22))
                .frame(width: 460, height: 460)
                .blur(radius: 80)
                .offset(x: -360, y: -220)

            Circle()
                .fill(Color(red: 0.23, green: 0.74, blue: 0.68).opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 360, y: 220)
        }
    }
}

private struct DropTargetOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 46, weight: .bold))
                Text("把照片放進來")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("NekoPixelMedic 會直接建立第一輪 repair preview。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
    }
}
