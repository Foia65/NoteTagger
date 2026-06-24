import Foundation
import Speech
import Combine
import AVFoundation

@MainActor
final class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false

    init() {
        #if DEBUG
        if #available(iOS 26, *) {
            Task {
                let locales = await SpeechTranscriber.supportedLocales
                let identifiers = locales.map { $0.identifier(.bcp47) }.sorted()
                print("[TranscriptionManager] Supported locales (\(identifiers.count)):")
                for id in identifiers {
                    print("  - \(id)")
                }
                let current = Locale.current.identifier(.bcp47)
                let supported = identifiers.contains(current)
                print("[TranscriptionManager] Current locale: \(current) (supported: \(supported))")
            }
        } else {
            print("[TranscriptionManager] iOS 26+ required for transcription")
        }
        #endif
    }

    func ensureModel(locale: Locale = .current) async throws {
        guard #available(iOS 26, *) else { return }
        let installed = await Set(SpeechTranscriber.installedLocales.map { $0.identifier(.bcp47) })
        let wanted = locale.identifier(.bcp47)
        if !installed.contains(wanted) {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [SpeechTranscriber(locale: locale, preset: .transcription)]) {
                try await request.downloadAndInstall()
            }
        }
    }

    func transcribe(url: URL, locale: Locale = .current) async throws -> String {
        guard #available(iOS 26, *) else {
            throw TranscriptionError.unsupportedOS
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        let audioFile = try AVAudioFile(forReading: url)
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        async let transcriptionFuture = transcriber.results.reduce("") { str, result in
            if result.isFinal {
                return str + String(result.text.characters)
            }
            return str
        }

        if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
            try await analyzer.finalizeAndFinish(through: lastSample)
        } else {
            await analyzer.cancelAndFinishNow()
        }

        return try await transcriptionFuture
    }
}

enum TranscriptionError: LocalizedError {
    case unsupportedOS

    var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            return String(localized: "transcription_error_unsupported")
        }
    }
}
