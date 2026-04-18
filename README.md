# NekoPixelMedic

> 100% on-device macOS photo repair tool｜100% 本機處理的 macOS 照片修復工具｜100% 本地处理的 macOS 照片修复工具｜100% オンデバイスの macOS 写真修復ツール

[English](#-english) ｜ [繁體中文](#-繁體中文) ｜ [简体中文](#-简体中文) ｜ [日本語](#-日本語)

---

## 🇺🇸 English

### Overview

**NekoPixelMedic** is a native macOS photo repair tool for "injured" photos — blurry, low-resolution, old and yellowed, face-distorted, noisy.

Everything runs locally on your Mac. **Your photos never leave your device.**

### ✨ Features (Planned)

- 🔧 **Deblur** — Fix motion blur and out-of-focus shots
- 📈 **Super Resolution** — Upscale to 2x / 4x
- 🕰️ **Old Photo Restoration** — Yellowing, scratches, fading
- 👤 **Face Restoration** — Dedicated face detail recovery
- 🔇 **Denoise** — Remove high-ISO / low-light noise

### 🛠️ Tech Stack

- **Swift + SwiftUI** — Native macOS UI
- **Core ML** — Apple Silicon optimized
- **100% local inference** — No cloud dependency

### 🧠 Model Strategy

To keep the app binary small, models are downloaded on demand:

- **Bundled**: Lightweight Core ML models (baseline repair)
- **Optional downloads**: Advanced open-source models
  - Real-ESRGAN (super resolution)
  - GFPGAN (face restoration)
  - CodeFormer (face restoration + enhancement)
  - Community-contributed models

### 💻 Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon recommended (M1 / M2 / M3 / M4)
- Intel Mac compatibility TBD

### 🔒 Privacy

- 100% on-device processing
- Zero network requests (except model downloads)
- No telemetry, no analytics, no tracking

### 🚧 Status

Early development. Currently in architecture design and prototyping.

### 📦 Install

Not yet released. Planned distribution:
- Direct DMG download
- Mac App Store (under evaluation)

### 🤝 Contributing

Free and open source. Issues and PRs welcome:

- Bug reports: open an Issue
- New features / model integrations: submit a PR
- Translations: help us add more languages

### 📄 License

MIT License — see [LICENSE](./LICENSE)

---

## 🇹🇼 繁體中文

### 簡介

**NekoPixelMedic** 是一款 macOS 原生照片修復工具，專治各種「受傷」的照片——模糊、低解析度、老舊泛黃、人臉失真、雜訊。

所有處理都在你的 Mac 本機完成，**照片不會上傳任何伺服器**。

### ✨ 功能（規劃中）

- 🔧 **去模糊** — 修復手震、失焦照片
- 📈 **超解析度放大** — 低解析度放大至 2x / 4x
- 🕰️ **老照片修復** — 泛黃、刮痕、褪色
- 👤 **人臉修復** — 專門針對人臉細節
- 🔇 **降噪** — 移除高 ISO / 低光雜訊

### 🛠️ 技術棧

- **Swift + SwiftUI** — macOS 原生 UI
- **Core ML** — Apple Silicon 最佳化
- **100% 本機推論** — 不依賴任何雲端服務

### 🧠 模型策略

為了避免主程式體積過大，模型採用**按需下載**機制：

- **內建**：輕量化 Core ML 模型（基礎修復）
- **選配下載**：進階開源模型，使用者可按需啟用
  - Real-ESRGAN（超解析度）
  - GFPGAN（人臉修復）
  - CodeFormer（人臉修復 + 強化）
  - 其他社群貢獻模型

### 💻 系統需求

- macOS 14 (Sonoma) 或以上
- Apple Silicon 建議（M1 / M2 / M3 / M4）
- Intel Mac 相容性待測試

### 🔒 隱私

- 100% 本機處理
- 零網路請求（模型下載除外）
- 無遙測、無分析、無追蹤

### 🚧 開發狀態

早期開發中。目前處於架構設計與原型階段。

### 📦 安裝

尚未發佈。未來將提供：
- DMG 直接下載
- Mac App Store（評估中）

### 🤝 貢獻

本專案免費、開源，歡迎 Issue / PR：

- 回報 bug：開 Issue
- 新功能 / 新模型整合：發 PR
- 文件翻譯：歡迎補其他語言

### 📄 授權

MIT License — 詳見 [LICENSE](./LICENSE)

---

## 🇨🇳 简体中文

### 简介

**NekoPixelMedic** 是一款 macOS 原生照片修复工具，专治各种「受伤」的照片——模糊、低分辨率、老旧泛黄、人脸失真、噪点。

所有处理都在你的 Mac 本机完成，**照片不会上传任何服务器**。

### ✨ 功能（规划中）

- 🔧 **去模糊** — 修复手抖、失焦照片
- 📈 **超分辨率放大** — 低分辨率放大至 2x / 4x
- 🕰️ **老照片修复** — 泛黄、划痕、褪色
- 👤 **人脸修复** — 专门针对人脸细节
- 🔇 **降噪** — 移除高 ISO / 低光噪点

### 🛠️ 技术栈

- **Swift + SwiftUI** — macOS 原生 UI
- **Core ML** — Apple Silicon 最佳化
- **100% 本地推理** — 不依赖任何云端服务

### 🧠 模型策略

为了避免主程序体积过大，模型采用**按需下载**机制：

- **内建**：轻量化 Core ML 模型（基础修复）
- **选配下载**：进阶开源模型，用户可按需启用
  - Real-ESRGAN（超分辨率）
  - GFPGAN（人脸修复）
  - CodeFormer（人脸修复 + 强化）
  - 其他社群贡献模型

### 💻 系统需求

- macOS 14 (Sonoma) 或以上
- Apple Silicon 建议（M1 / M2 / M3 / M4）
- Intel Mac 兼容性待测试

### 🔒 隐私

- 100% 本地处理
- 零网络请求（模型下载除外）
- 无遥测、无分析、无追踪

### 🚧 开发状态

早期开发中。目前处于架构设计与原型阶段。

### 📦 安装

尚未发布。未来将提供：
- DMG 直接下载
- Mac App Store（评估中）

### 🤝 贡献

本项目免费、开源，欢迎 Issue / PR：

- 报告 bug：开 Issue
- 新功能 / 新模型集成：发 PR
- 文档翻译：欢迎补其他语言

### 📄 授权

MIT License — 详见 [LICENSE](./LICENSE)

---

## 🇯🇵 日本語

### 概要

**NekoPixelMedic** は、「傷ついた」写真——ブレ、低解像度、古びて黄ばんだ写真、顔の歪み、ノイズ——を修復する macOS ネイティブツールです。

すべての処理は Mac 本体で完結します。**写真は一切サーバーにアップロードされません。**

### ✨ 機能（計画中）

- 🔧 **ブレ補正** — 手ブレ・ピンボケの修復
- 📈 **超解像** — 2x / 4x のアップスケール
- 🕰️ **古い写真の復元** — 黄ばみ、傷、色褪せ
- 👤 **顔修復** — 顔のディテール復元に特化
- 🔇 **ノイズ除去** — 高 ISO / 低光量のノイズ除去

### 🛠️ 技術スタック

- **Swift + SwiftUI** — macOS ネイティブ UI
- **Core ML** — Apple Silicon 最適化
- **100% ローカル推論** — クラウド依存なし

### 🧠 モデル戦略

アプリ本体のサイズを抑えるため、モデルはオンデマンドでダウンロード：

- **内蔵**：軽量 Core ML モデル（基本修復）
- **追加ダウンロード**：高度なオープンソースモデル
  - Real-ESRGAN（超解像）
  - GFPGAN（顔修復）
  - CodeFormer（顔修復 + 強化）
  - コミュニティ貢献モデル

### 💻 動作環境

- macOS 14 (Sonoma) 以降
- Apple Silicon 推奨（M1 / M2 / M3 / M4）
- Intel Mac の対応は未確認

### 🔒 プライバシー

- 100% オンデバイス処理
- ネットワークリクエストなし（モデルダウンロード時を除く）
- テレメトリ・分析・トラッキング一切なし

### 🚧 開発状況

初期開発中。現在はアーキテクチャ設計とプロトタイピングの段階です。

### 📦 インストール

未リリース。今後の配布予定：
- DMG 直接ダウンロード
- Mac App Store（検討中）

### 🤝 コントリビューション

無料・オープンソース。Issue と PR 歓迎：

- バグ報告：Issue を開いてください
- 新機能 / 新モデル統合：PR を送ってください
- 翻訳：他の言語の追加も歓迎

### 📄 ライセンス

MIT License — [LICENSE](./LICENSE) を参照

---

## 🐱 Why Neko?

NekoPixelMedic is part of the **Neko series** of macOS tools｜NekoPixelMedic 是 **Neko 系列** macOS 工具的一員｜是 **Neko 系列** macOS 工具的一员｜NekoPixelMedic は **Neko シリーズ** macOS ツールの一つです：

- [NekoAV](https://github.com/MakiDevelop/NekoAV)
- [NekoFaceCluster](https://github.com/MakiDevelop/NekoFaceCluster)
- [NekoPress](https://github.com/MakiDevelop/NekoPress)
- **NekoPixelMedic** ← You are here ｜ 你在這裡 ｜ 你在这里 ｜ここにいます
